use super::{
    super::{Error, raw::Library},
    api::WrapperApi,
};

impl<T> WrapperApi for Option<T>
where
    T: WrapperApi,
{
    unsafe fn load(lib: &Library) -> Result<Self, Error> {
        unsafe {
            match T::load(lib) {
                Ok(val) => Ok(Some(val)),
                Err(_) => Ok(None),
            }
        }
    }
}
