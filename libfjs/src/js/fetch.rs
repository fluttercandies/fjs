use crate::api::value::JsValue;
use crate::js::value::JsonValue;
use bytes::Bytes;
use cookie_store::{CookieStore, RawCookie, RawCookieParseError};
use reqwest::header::{HeaderName, HeaderValue};
use rquickjs::function::{Async, Func, Rest};
use rquickjs::{ArrayBuffer, Ctx, Exception, FromJs, Function, IntoJs, Object, Result, Value};
use std::fs::OpenOptions;
use std::io::BufWriter;
use std::str;
use std::sync::{Arc, LockResult, PoisonError, RwLockReadGuard};
use std::sync::{RwLock, RwLockWriteGuard};

struct InnerCookieStore(Arc<RwLock<CookieStore>>);

fn write_cookies(
    cookie_store: &mut CookieStore,
    cookie_headers: &mut dyn Iterator<Item = &HeaderValue>,
    url: &url::Url,
) {
    let cookies = cookie_headers.filter_map(|val| {
        str::from_utf8(val.as_bytes())
            .map_err(RawCookieParseError::from)
            .and_then(RawCookie::parse)
            .map(|c| c.into_owned())
            .ok()
    });
    cookie_store.store_response_cookies(cookies, url);
}

fn read_cookies(cookie_store: &CookieStore, url: &url::Url) -> Option<HeaderValue> {
    let s = cookie_store
        .get_request_values(url)
        .map(|(name, value)| format!("{}={}", name, value))
        .collect::<Vec<_>>()
        .join("; ");

    if s.is_empty() {
        return None;
    }

    HeaderValue::from_maybe_shared(Bytes::from(s)).ok()
}

impl InnerCookieStore {
    pub const fn new(cookie_store: Arc<RwLock<CookieStore>>) -> InnerCookieStore {
        InnerCookieStore(cookie_store)
    }
}

impl reqwest::cookie::CookieStore for InnerCookieStore {
    fn set_cookies(&self, cookie_headers: &mut dyn Iterator<Item = &HeaderValue>, url: &url::Url) {
        let mut write = self.0.write().unwrap();
        write_cookies(&mut write, cookie_headers, url);
    }

    fn cookies(&self, url: &url::Url) -> Option<HeaderValue> {
        let read = self.0.read().unwrap();
        read_cookies(&read, url)
    }
}

pub struct RequestInit<'js> {
    method: reqwest::Method,
    body: Option<Value<'js>>,
    headers: Option<reqwest::header::HeaderMap>,
}

impl Default for RequestInit<'_> {
    fn default() -> Self {
        RequestInit {
            method: reqwest::Method::GET,
            body: None,
            headers: None,
        }
    }
}

async fn _fetch<'js>(ctx: Ctx<'js>, args: Rest<Value<'js>>) -> anyhow::Result<Object<'js>> {
    let url = args
        .get(0)
        .ok_or(anyhow::anyhow!("url is required"))?
        .as_string()
        .ok_or(anyhow::anyhow!("url must be a string"))?
        .to_string()?;
    let init = args.get(1);

    let init = if let Some(init) = init {
        if init.is_object() {
            let init = init.as_object().unwrap();
            let method: Result<Value> = init.get("method");
            let method = if let Ok(method) = method {
                if method.is_string() {
                    let method = method.as_string().unwrap().to_string()?;
                    match method.as_ref() {
                        "GET" => reqwest::Method::GET,
                        "POST" => reqwest::Method::POST,
                        "PUT" => reqwest::Method::PUT,
                        "DELETE" => reqwest::Method::DELETE,
                        "PATCH" => reqwest::Method::PATCH,
                        "HEAD" => reqwest::Method::HEAD,
                        _ => {
                            return Err(anyhow::anyhow!(
                                "method must be one of GET, POST, PUT, DELETE, PATCH"
                            ))
                        }
                    }
                } else {
                    return Err(anyhow::anyhow!("method must be a string"));
                }
            } else {
                reqwest::Method::GET
            };
            let body: Result<Value> = init.get("body");
            let body = if let Ok(body) = body {
                if body.is_undefined() || body.is_null() {
                    None
                } else {
                    Some(body)
                }
            } else {
                None
            };
            let headers: Result<Value> = init.get("headers");
            let headers = if let Ok(headers) = headers {
                if headers.is_object() {
                    let headers = headers.into_object().unwrap();
                    let mut header_map = reqwest::header::HeaderMap::new();
                    for header in headers.props() {
                        let (k, v): (Value, Value) = header?;
                        if v.is_string() {
                            let key: HeaderName = k.as_string().unwrap().to_string()?.parse()?;
                            let value = v.as_string().unwrap().to_string()?.parse()?;
                            header_map.insert(key, value);
                        } else {
                            return Err(anyhow::anyhow!("header values must be strings"));
                        }
                    }
                    Some(header_map)
                } else if headers.is_undefined() || headers.is_null() {
                    None
                } else {
                    return Err(anyhow::anyhow!("headers must be an object"));
                }
            } else {
                None
            };
            RequestInit {
                method,
                body,
                headers,
            }
        } else if init.is_undefined() || init.is_null() {
            RequestInit::default()
        } else {
            return Err(anyhow::anyhow!("init must be an object"));
        }
    } else {
        RequestInit::default()
    };

    let client = reqwest::Client::builder().build()?;
    let header_map = init.headers.unwrap_or_default();
    let mut builder = client.request(init.method, url.as_str());
    if init.body.is_some() {
        let body = init.body.unwrap();
        let header_value = header_map.get(&reqwest::header::CONTENT_TYPE);
        match header_value {
            Some(v) => {
                let header_value = v.to_str()?;
                if header_value.contains("x-www-form-urlencoded") {
                    if body.is_string() {
                        let body = body.as_string().unwrap().to_string()?;
                        let decoded: Vec<(String, String)> = serde_urlencoded::from_str(&body)?;
                        builder = builder.form(&decoded);
                    } else if body.is_object() {
                        let js_value = JsValue::from_js(&ctx, body)?;
                        match js_value {
                            JsValue::Object(v) => {
                                let mut form = vec![];
                                for kv in v.iter() {
                                    let key = kv.key.as_str();
                                    let value = &kv.value;
                                    match value {
                                        JsValue::String(v) => {
                                            form.push((key, v.clone()));
                                        }
                                        JsValue::Array(v) => {
                                            for v in v {
                                                match v {
                                                    JsValue::String(v) => {
                                                        form.push((key, v.clone()));
                                                    }
                                                    _ => {
                                                        return Err(anyhow::anyhow!(
                                                            "form values must be strings"
                                                        ));
                                                    }
                                                }
                                            }
                                        }
                                        JsValue::Boolean(v) => {
                                            form.push((key, v.to_string()));
                                        }
                                        JsValue::Integer(v) => {
                                            form.push((key, v.to_string()));
                                        }
                                        JsValue::Float(v) => {
                                            form.push((key, v.to_string()));
                                        }
                                        JsValue::Bigint(v) => {
                                            form.push((key, v.clone()));
                                        }
                                        JsValue::Null => {
                                            form.push((key, "".to_string()));
                                        }
                                        _ => {
                                            return Err(anyhow::anyhow!(
                                                "form values must be strings"
                                            ));
                                        }
                                    }
                                }
                                builder = builder.form(&form);
                            }
                            _ => {
                                return Err(anyhow::anyhow!("body must be an object"));
                            }
                        }
                    } else {
                        return Err(anyhow::anyhow!("body must be a string or object"));
                    }
                } else if header_value.contains("multipart/form-data") {
                    return Err(anyhow::anyhow!("multipart/form-data is not supported"));
                } else {
                    if body.is_string() {
                        let body = body.as_string().unwrap().to_string()?;
                        builder = builder.body(body);
                    } else {
                        let value = JsonValue::from_js(&ctx, body)?;
                        builder = builder.json(&value.0);
                    }
                }
            }
            None => {
                if body.is_string() {
                    let body = body.as_string().unwrap().to_string()?;
                    builder = builder.body(body);
                } else {
                    let value = JsonValue::from_js(&ctx, body)?;
                    builder = builder.json(&value.0);
                }
            }
        }
    }
    let res = builder.headers(header_map).send().await?;
    let code = res.status().as_u16();
    let response = Object::new(ctx.clone())?;
    response.set("type", "basic".into_js(&ctx)?)?;
    response.set("url", res.url().as_str().into_js(&ctx)?)?;
    response.set(
        "statusText",
        res.status()
            .canonical_reason()
            .unwrap_or("")
            .into_js(&ctx)?,
    )?;
    response.set("status", code.into_js(&ctx)?)?;
    response.set("ok", (code == 200).into_js(&ctx)?)?;
    response.set("redirected", res.url().as_str() != url.as_str())?;

    let headers = Object::new(ctx.clone())?;
    for (k, v) in res.headers() {
        headers.set(k.as_str(), v.to_str()?.into_js(&ctx)?)?;
    }
    response.set("headers", headers.into_js(&ctx)?)?;

    let bytes = res.bytes().await?;
    let c1 = ctx.clone();
    let bytes1 = bytes.clone();
    response.set(
        "arrayBuffer",
        Function::new(ctx.clone(), move || {
            ArrayBuffer::new(c1.clone(), bytes1.to_vec()).into_js(&c1)
        }),
    )?;

    let c2 = ctx.clone();
    let bytes2 = bytes.clone();
    response.set(
        "text",
        Function::new(ctx.clone(), move || {
            let text = str::from_utf8(&*bytes2);
            text.into_js(&c2)
        }),
    )?;

    response.set(
        "json",
        Function::new(ctx.clone(), move || {
            let json = serde_json::from_slice::<serde_json::Value>(&bytes);
            match json {
                Ok(json) => JsonValue::from(json).into_js(&ctx),
                Err(e) => Err(Exception::throw_message(&ctx, &e.to_string())),
            }
        }),
    )?;
    Ok(response)
}

pub async fn _inner<'js>(ctx: Ctx<'js>, args: Rest<Value<'js>>) -> Result<Object<'js>> {
    match _fetch(ctx.clone(), args).await {
        Ok(v) => Ok(v),
        Err(e) => {
            log::error!("{}", e.to_string());
            Err(ctx.throw(e.to_string().into_js(&ctx)?))
        }
    }
}

pub fn setup_fetch(ctx: &Ctx) -> Result<()> {
    let object = ctx.globals();
    let fetch = Func::from(Async(_inner));
    object.set("fetch", fetch)?;
    Ok(())
}
