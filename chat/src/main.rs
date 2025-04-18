use image::ImageFormat;
use once_cell::sync::Lazy;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::{
    env,
    fs::{canonicalize, read},
    io::{self, Write},
    path::PathBuf,
    thread,
};
use wry::application::window::{Icon, Window};
use wry::{
    application::{
        event::{Event, StartCause, WindowEvent},
        event_loop::{ControlFlow, EventLoop},
        window::WindowBuilder,
    },
    webview::WebViewBuilder,
};

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

fn main() -> wry::Result<()> {
    // println!("{}", serde_json::to_string_pretty(&Message::Focus).unwrap());
    let event_loop = EventLoop::with_user_event();
    let window = WindowBuilder::new()
        .with_title(WINDOW_TITLE)
        .with_window_icon(Some(ICON.clone()))
        .build(&event_loop)?;
    let webview = WebViewBuilder::new(window)?
        .with_devtools(true)
        .with_clipboard(true)
        .with_custom_protocol("wry".into(), |request| {
            let path = request.uri().path();
            // Read the file content from file path
            let content = if path == "/" {
                INDEX_HTML.as_bytes().into()
            } else {
                read(canonicalize(
                    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(&path[1..]),
                )?)?
                .into()
            };

            let mimetype = if path.ends_with(".html") || path == "/" {
                "text/html"
            } else if path.ends_with(".js") {
                "text/javascript"
            } else {
                unimplemented!();
            };

            wry::http::Response::builder()
                .header(wry::http::header::CONTENT_TYPE, mimetype)
                .body(content)
                .map_err(Into::into)
        })
        .with_ipc_handler(move |_window: &Window, req: String| {
            let mut lock = io::stdout().lock();
            let _ = writeln!(lock, "{req}");
        })
        .with_url(BASE_URL)?
        //.with_url("http://localhost:3000")?
        .build()?;

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
                    webview.window().set_focus();
                    if env::consts::OS == "linux" {
                        let _ = std::process::Command::new("wmctrl")
                            .args(["-a", WINDOW_TITLE])
                            .output();
                    }
                }
                Ok(Message::SetOnTop(on_top)) => {
                    webview.window().set_always_on_top(on_top);
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
