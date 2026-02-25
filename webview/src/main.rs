use image::ImageFormat;
use once_cell::sync::Lazy;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::{
    borrow::Cow,
    env,
    fs::{canonicalize, read},
    io::{self, Write},
    path::PathBuf,
    thread,
};
use tao::{
    event::{Event, StartCause, WindowEvent},
    event_loop::{ControlFlow, EventLoopBuilder},
    window::{Icon, WindowBuilder},
};
use wry::WebViewBuilder;

#[derive(Deserialize, Serialize)]
#[serde(tag = "command", content = "data")]
enum Message {
    #[serde(rename = "focus")]
    Focus,
    #[serde(rename = "set_always_on_top")]
    SetOnTop(bool),
}

const WINDOW_TITLE: &str = "Tabnine Chat";

const BASE_URL: &str = "wry://localhost";

static INDEX_HTML: Lazy<String> = Lazy::new(|| {
    let index_html = read(PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("./index.html")).unwrap();
    Regex::new("(href|src)=\"/static")
        .unwrap()
        .replace_all(
            &String::from_utf8(index_html).unwrap(),
            format!("$1=\"{BASE_URL}/static"),
        )
        .to_string()
});

static ICON: Lazy<Icon> = Lazy::new(|| {
    let bytes: Vec<u8> = include_bytes!("../icon.png").to_vec();
    let imagebuffer = image::load_from_memory_with_format(&bytes, ImageFormat::Png)
        .unwrap()
        .into_rgba8();
    let (icon_width, icon_height) = imagebuffer.dimensions();
    let icon_rgba = imagebuffer.into_raw();
    Icon::from_rgba(icon_rgba, icon_width, icon_height).unwrap()
});

fn mime_type(path: &str) -> &'static str {
    if path.ends_with(".html") || path == "/" {
        "text/html"
    } else if path.ends_with(".js") {
        "text/javascript"
    } else if path.ends_with(".css") {
        "text/css"
    } else if path.ends_with(".json") {
        "application/json"
    } else if path.ends_with(".png") {
        "image/png"
    } else if path.ends_with(".svg") {
        "image/svg+xml"
    } else if path.ends_with(".woff") || path.ends_with(".woff2") {
        "font/woff2"
    } else {
        "application/octet-stream"
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let event_loop = EventLoopBuilder::<String>::with_user_event().build();
    let window = WindowBuilder::new()
        .with_title(WINDOW_TITLE)
        .with_window_icon(Some(ICON.clone()))
        .build(&event_loop)?;

    let builder = WebViewBuilder::new()
        .with_devtools(true)
        .with_clipboard(true)
        .with_custom_protocol("wry".into(), |_id, request| {
            let path = request.uri().path();
            let content: Cow<'static, [u8]> = if path == "/" {
                Cow::Owned(INDEX_HTML.as_bytes().to_vec())
            } else {
                let file_path = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(&path[1..]);
                match canonicalize(&file_path).and_then(|p| read(p)) {
                    Ok(bytes) => Cow::Owned(bytes),
                    Err(_) => {
                        return http::Response::builder()
                            .status(404)
                            .body(Cow::Borrowed(b"Not Found" as &[u8]))
                            .unwrap();
                    }
                }
            };

            http::Response::builder()
                .header(http::header::CONTENT_TYPE, mime_type(path))
                .body(content)
                .unwrap()
        })
        .with_ipc_handler(move |req| {
            let mut lock = io::stdout().lock();
            let _ = writeln!(lock, "{}", req.body());
        })
        .with_url(BASE_URL);

    #[cfg(target_os = "linux")]
    let webview = {
        use tao::platform::unix::WindowExtUnix;
        use wry::WebViewBuilderExtUnix;
        let vbox = window.default_vbox().unwrap();
        builder.build_gtk(vbox)?
    };

    #[cfg(not(target_os = "linux"))]
    let webview = builder.build(&window)?;

    let proxy = event_loop.create_proxy();
    thread::spawn(move || loop {
        let mut buffer = String::new();
        io::stdin().read_line(&mut buffer).unwrap();
        let _ = proxy.send_event(buffer);
    });

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::NewEvents(StartCause::Init) => (),
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            Event::UserEvent(message) => match serde_json::from_str::<Message>(&message) {
                Ok(Message::Focus) => {
                    window.set_focus();
                    if env::consts::OS == "linux" {
                        let _ = std::process::Command::new("wmctrl")
                            .args(["-a", WINDOW_TITLE])
                            .output();
                    }
                }
                Ok(Message::SetOnTop(on_top)) => {
                    window.set_always_on_top(on_top);
                }
                _ => {
                    let _ =
                        webview.evaluate_script(&format!("window.postMessage({message},\"*\")"));
                }
            },
            _ => (),
        }
    });
}