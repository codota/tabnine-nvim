use once_cell::sync::Lazy;
use regex::Regex;
use std::{
    env,
    fs::{canonicalize, read},
    io::{self, Write},
    path::PathBuf,
    thread,
};
use wry::application::window::Window;
use wry::{
    application::{
        event::{Event, StartCause, WindowEvent},
        event_loop::{ControlFlow, EventLoop},
        window::WindowBuilder,
    },
    webview::WebViewBuilder,
};

const BASE_URL: &str = "wry://localhost";
const INDEX_HTML_TEMPLATE: &[u8] = include_bytes!("../index.html");
static INDEX_HTML: Lazy<String> = Lazy::new(|| {
    Regex::new("(href|src)=\"/static")
        .unwrap()
        .replace_all(
            &String::from_utf8(INDEX_HTML_TEMPLATE.to_vec()).unwrap(),
            format!("$1=\"{BASE_URL}/static"),
        )
        .to_string()
});

fn main() -> wry::Result<()> {
    let event_loop = EventLoop::with_user_event();
    let window = WindowBuilder::new()
        .with_title("Tabnine Chat")
        .build(&event_loop)?;
    let _webview = WebViewBuilder::new(window)?
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
            Event::UserEvent(message) => {
                let _ = _webview.evaluate_script(&format!("window.postMessage({message},\"*\")"));
            }
            _ => (),
        }
    });
}
