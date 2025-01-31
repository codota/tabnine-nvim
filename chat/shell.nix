# shell.nix
#
# this is a nix file which can create a shell with the dependencies necessary 
# to build tabnine-chat. It assumes you're reasonably familiar with the nix 
# toolchain.
#
# To use it:
#
# $ cd chat
# $ nix-shell
# these 11 paths will be fetched (156.39 MiB download, 739.97 MiB unpacked):
#   /nix/store/z8dx4c6z528qi2w1p38yzg17g8q5jnln-cargo-1.77.2
# <snip...>
# [nix-shell]$ cargo build --release
#    Compiling serde v1.0.164
# <snip...>
#    Compiling tabnine_chat v0.1.0 (/home/sean/Work/tabnine-nvim/chat)
#     Finished release [optimized] target(s) in 1m 42s
#
# built against 960fae2187687ff0929775ffedb6f05172b990d2 with nixos 24.05
#
# A flake could have been provided, but given that tabnine-nvim is often 
# managed by lazy, can change quite frequently and is a bit divorced from the 
# nix ecosystem, it seemed that a reasonable solution was just to support the 
# cargo build process inside the chat directory.

{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell rec {
    buildInputs = with pkgs; [
      cargo
      rustc
      pkg-config
    ];

    nativeBuildInputs = with pkgs; [
      glib
      gdk-pixbuf
      libsoup_3
      pango
      gtk3
      webkitgtk_4_1
    ];
  }
