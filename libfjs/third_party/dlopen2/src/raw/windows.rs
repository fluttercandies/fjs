use crate::utils;

use super::{
    super::err::Error,
    common::{AddressInfo, OverlappingSymbol},
};
use std::{
    ffi::{CStr, OsStr, OsString},
    io::Error as IoError,
    mem::size_of,
    os::windows::ffi::{OsStrExt, OsStringExt},
    ptr::null_mut,
    slice,
    sync::{
        Mutex, OnceLock,
        atomic::{AtomicBool, Ordering},
    },
};
use windows_sys::{
    Win32::{
        Foundation::{ERROR_CALL_NOT_IMPLEMENTED, FreeLibrary, GetLastError, HMODULE, TRUE},
        System::{
            Diagnostics::Debug::{
                SYMBOL_INFOW, SetErrorMode, SetThreadErrorMode, SymFromAddrW, SymGetModuleBase64,
                SymInitializeW, THREAD_ERROR_MODE,
            },
            LibraryLoader::{GetModuleFileNameW, GetModuleHandleExW, GetProcAddress, LoadLibraryW},
            Threading::GetCurrentProcess,
        },
    },
    core::PCSTR,
};

static USE_ERRORMODE: AtomicBool = AtomicBool::new(false);

const PATH_MAX: u32 = 256;
const MAX_SYMBOL_LEN: usize = 256;

struct SetErrorModeData {
    pub count: u32,
    pub previous: THREAD_ERROR_MODE,
}

static SET_ERR_MODE_DATA: Mutex<SetErrorModeData> = Mutex::new(SetErrorModeData {
    count: 0,
    previous: 0,
});
static SYM_MUTEX: OnceLock<Mutex<()>> = OnceLock::new();

pub type Handle = HMODULE;

/*
Windows has an ugly feature: by default not finding the given library opens a window
and passes control to the user.
To fix this wee need to change thread/process error mode for the moment when the function is called
and then revert it to the previous value.

Since Windows 7 the SetThreadErrorMode function is supported. It sets error mode for the given
thread. Older systems require calling SetErrorMode. This function sets error mode for the whole
process.

https://msdn.microsoft.com/pl-pl/library/windows/desktop/dd553630(v=vs.85).aspx
*/

const ERROR_MODE: THREAD_ERROR_MODE = 1; // app handles everything

enum ErrorModeGuard {
    ThreadPreviousValue(THREAD_ERROR_MODE),
    DoNothing,
    Process,
}

impl ErrorModeGuard {
    fn new() -> Result<ErrorModeGuard, IoError> {
        if !USE_ERRORMODE.load(Ordering::Acquire) {
            let mut previous: THREAD_ERROR_MODE = 0;
            if unsafe { SetThreadErrorMode(ERROR_MODE, &mut previous) } == 0 {
                //error. On some systems SetThreadErrorMode may not be implemented
                let error = unsafe { GetLastError() };
                if error == ERROR_CALL_NOT_IMPLEMENTED {
                    USE_ERRORMODE.store(true, Ordering::Release);
                } else {
                    //this is an actual error
                    //SetErrorMode never fails. Shouldn't we use it now?
                    return Err(IoError::from_raw_os_error(error as i32));
                }
            } else {
                return Ok(if previous == ERROR_MODE {
                    ErrorModeGuard::DoNothing
                } else {
                    ErrorModeGuard::ThreadPreviousValue(previous)
                });
            }
        }
        //several threads may be opening libraries at the same time.
        //we need to make sure that only the first one sets the erro mode
        //and only the last reverts it to the original value

        //poisoning should never happen
        let mut lock = SET_ERR_MODE_DATA.lock().expect("Mutex got poisoned");
        if lock.count == 0 {
            lock.previous = unsafe { SetErrorMode(ERROR_MODE) };
            if lock.previous == ERROR_MODE {
                return Ok(ErrorModeGuard::DoNothing);
            }
        }
        lock.count += 1;
        Ok(ErrorModeGuard::Process)
    }
}

impl Drop for ErrorModeGuard {
    fn drop(&mut self) {
        match *self {
            ErrorModeGuard::DoNothing => (),
            ErrorModeGuard::Process => {
                //poisoning should never happen
                let mut lock = SET_ERR_MODE_DATA.lock().expect("Mutex got poisoned");
                lock.count -= 1;
                if lock.count == 0 {
                    unsafe { SetErrorMode(lock.previous) };
                }
            }
            ErrorModeGuard::ThreadPreviousValue(previous) => unsafe {
                SetThreadErrorMode(previous, null_mut());
            },
        }
    }
}

unsafe fn get_win_error() -> IoError {
    unsafe {
        let error = GetLastError();
        if error == 0 {
            IoError::other("Could not obtain information about the error")
        } else {
            IoError::from_raw_os_error(error as i32)
        }
    }
}

#[inline]
pub unsafe fn get_sym(handle: Handle, name: &CStr) -> Result<*mut (), Error> {
    unsafe {
        let symbol = GetProcAddress(handle, name.as_ptr() as PCSTR);
        match symbol {
            Some(symbol) => Ok(symbol as *mut ()),
            None => Err(Error::SymbolGettingError(get_win_error())),
        }
    }
}

#[inline]
pub unsafe fn open_self() -> Result<Handle, Error> {
    unsafe {
        let mut handle: Handle = null_mut();
        if GetModuleHandleExW(0, null_mut(), &mut handle) == 0 {
            Err(Error::OpeningLibraryError(get_win_error()))
        } else {
            Ok(handle)
        }
    }
}

#[inline]
pub unsafe fn open_lib(name: &OsStr, _flags: Option<i32>) -> Result<Handle, Error> {
    unsafe {
        let wide_name: Vec<u16> = name.encode_wide().chain(Some(0)).collect();
        let _guard = match ErrorModeGuard::new() {
            Ok(val) => val,
            Err(err) => return Err(Error::OpeningLibraryError(err)),
        };
        let handle = LoadLibraryW(wide_name.as_ptr());
        if handle.is_null() {
            Err(Error::OpeningLibraryError(get_win_error()))
        } else {
            Ok(handle)
        }
    }
}

#[inline]
pub unsafe fn addr_info_init() {
    unsafe {
        // calls to Sym* functions are not thread safe.
        SYM_MUTEX.get_or_init(|| {
            let process_handle = GetCurrentProcess();
            let _result = SymInitializeW(process_handle, null_mut(), TRUE);
            Mutex::new(())
        });
    }
}

#[inline]
pub unsafe fn addr_info_obtain(addr: *const ()) -> Result<AddressInfo, Error> {
    unsafe {
        let process_handle = GetCurrentProcess();

        let mut buffer = utils::maybe_uninit_uninit_array::<u16, { PATH_MAX as usize }>();
        let mut symbol_buffer = utils::maybe_uninit_uninit_array::<
            u8,
            { size_of::<SYMBOL_INFOW>() + MAX_SYMBOL_LEN * size_of::<u16>() },
        >();
        let (module_base, path_len, symbol_info, result) = {
            // calls to Sym* functions are not thread safe.
            let mut _lock = SYM_MUTEX.get().unwrap().lock().expect("Mutex got poisoned");
            let module_base = SymGetModuleBase64(process_handle, addr as u64);

            if module_base == 0 {
                return Err(Error::AddrNotMatchingDll(get_win_error()));
            }

            let path_len =
                GetModuleFileNameW(module_base as HMODULE, buffer[0].as_mut_ptr(), PATH_MAX);
            if path_len == 0 {
                return Err(Error::AddrNotMatchingDll(get_win_error()));
            }
            let symbol_info: *mut SYMBOL_INFOW = symbol_buffer.as_mut_ptr() as *mut SYMBOL_INFOW;

            (*symbol_info).SizeOfStruct = size_of::<SYMBOL_INFOW>() as u32;
            (*symbol_info).MaxNameLen = MAX_SYMBOL_LEN as u32;
            let mut displacement: u64 = 0;
            let result = SymFromAddrW(process_handle, addr as u64, &mut displacement, symbol_info);
            (module_base, path_len, symbol_info, result)
        };

        let os = if result == TRUE {
            let name_len = (*symbol_info).NameLen as usize;
            let name_slice = slice::from_raw_parts((*symbol_info).Name.as_ptr(), name_len);
            let name = OsString::from_wide(name_slice)
                .to_string_lossy()
                .into_owned();
            //winapi doesn't have implementation of the SymSetOptions() for now
            //we need to manually strip off the namespace of the symbol.
            let name = match name.find("::") {
                None => name,
                Some(idx) => name[idx + 2..].to_string(),
            };
            Some(OverlappingSymbol {
                name,
                addr, // on Windows there is no overlappping, just a straight match
            })
        } else {
            None
        };
        Ok({
            AddressInfo {
                dll_path: OsString::from_wide(utils::maybe_uninit_slice_assume_init_ref(
                    &buffer[0..(path_len as usize)],
                ))
                .to_string_lossy()
                .into_owned(),
                dll_base_addr: module_base as *const (),
                overlapping_symbol: os,
            }
        })
    }
}

#[inline]
pub unsafe fn addr_info_cleanup() {}

#[inline]
pub fn close_lib(handle: Handle) -> Handle {
    if unsafe { FreeLibrary(handle) } == 0 {
        //this should not happen
        panic!("FreeLibrary() failed, the error is {}", unsafe {
            get_win_error()
        });
    }
    null_mut()
}
