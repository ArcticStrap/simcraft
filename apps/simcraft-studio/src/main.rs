//! SimCraft Studio — `simcraft-studio [model.simcraft]`.
//!
//! A `model.simcraft` argument opens in the diagram canvas at startup.
#![forbid(unsafe_code)]
#![deny(clippy::unwrap_used, clippy::expect_used, clippy::panic, clippy::unimplemented, clippy::todo, clippy::unreachable)]
#![cfg_attr(all(target_os = "windows", not(debug_assertions)), windows_subsystem = "windows")]

use simcraft_studio::{StudioApp, StudioOptions};

const USAGE: &str = "\
SimCraft Studio

usage: simcraft-studio [model.simcraft] [--run] [--select block] [--screenshot out.png]

  model.simcraft         open in the diagram canvas
  --run                  run the simulation immediately after loading
  --select <name>        select block <name> and display its params in the inspector
  --screenshot <path>    capture a screenshot of the window to <path> and exit
";

/// Window, taskbar and Dock icon (`assets/app-icon/`).
fn app_icon() -> egui::IconData {
    #[cfg(target_os = "macos")]
    let png: &[u8] = include_bytes!("../../../assets/app-icon/simcraft-macos-512.png");
    #[cfg(not(target_os = "macos"))]
    let png: &[u8] = include_bytes!("../../../assets/app-icon/simcraft-256.png");
    eframe::icon_data::from_png_bytes(png).unwrap_or_default()
}

fn main() -> eframe::Result<()> {
    let mut file: Option<std::path::PathBuf> = None;
    let mut autorun = false;
    let mut select: Option<String> = None;
    let mut screenshot: Option<std::path::PathBuf> = None;
    let mut args = std::env::args().skip(1);
    while let Some(a) = args.next() {
        match a.as_str() {
            "-h" | "--help" => {
                print!("{USAGE}");
                return Ok(());
            }
            "--run" => autorun = true,
            "--select" => {
                if let Some(name) = args.next() {
                    select = Some(name);
                } else {
                    eprintln!("missing argument for --select");
                }
            }
            "--screenshot" => {
                if let Some(path) = args.next() {
                    screenshot = Some(std::path::PathBuf::from(path));
                } else {
                    eprintln!("missing argument for --screenshot");
                }
            }
            s if !s.starts_with('-') && file.is_none() => file = Some(std::path::PathBuf::from(s)),
            s => eprintln!("unknown argument `{s}`"),
        }
    }
    let mut builder = egui::ViewportBuilder::default().with_inner_size([1280.0, 800.0]).with_icon(app_icon()).with_app_id("simcraft");
    if screenshot.is_some() {
        builder = builder.with_fullscreen(true);
    }
    let native = eframe::NativeOptions { viewport: builder, ..Default::default() };
    eframe::run_native(
        "SimCraft Studio",
        native,
        Box::new(move |cc| Ok(Box::new(StudioApp::new(cc, StudioOptions { startup_model: file.clone(), autorun, select, screenshot })))),
    )
}
