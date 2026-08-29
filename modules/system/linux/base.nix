{ config, pkgs, ... }: {
  config = {
    environment.sessionVariables = {
      PATH = [ "/usr/local/bin" "/usr/bin" "/opt/bin" ];
    };

    programs.nix-index.enable = true;

    # Enable nix-ld for precompiled dynamic binary execution
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; (import ../../core/base-packages.nix { inherit pkgs; }) ++ [
        stdenv.cc.cc
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        systemd

        libxcomposite
        libxtst
        libxrandr
        libxext
        libx11
        libxfixes
        libxcb
        libxdamage
        libxshmfence
        libxxf86vm
        libelf

        glib
        libGL
        libva

        networkmanager
        vulkan-loader
        libgbm
        libdrm
        libxcrypt
        zenity

        libxinerama
        libxcursor
        libxrender
        libxscrnsaver
        libxi
        libsm
        libice
        gnome2.GConf
        nspr
        nss
        cups
        libcap
        SDL2
        libusb1
        dbus-glib
        ffmpeg
        libudev0-shim

        gtk3
        icu
        libnotify
        gsettings-desktop-schemas

        libxt
        libxmu
        libogg
        libvorbis
        SDL
        SDL2_image
        glew_1_10
        libidn
        tbb

        flac
        freeglut
        libjpeg
        libpng
        libpng12
        libsamplerate
        libmikmod
        libtheora
        libtiff
        pixman
        speex
        SDL_image
        SDL_ttf
        SDL_mixer
        SDL2_ttf
        SDL2_mixer
        libcaca
        libcanberra
        libgcrypt
        libvpx
        librsvg
        libxft
        libvdpau

        pango
        cairo
        atk
        gdk-pixbuf
        fontconfig
        freetype
        dbus
        alsa-lib
        expat
        libxkbcommon
        libxcrypt-legacy
        libGLU

        fuse
        e2fsprogs
        gmp
        harfbuzz
        libgpg-error
        fribidi
        librsvg
        sane-backends
        pkcs11helper

        libpulseaudio
        pipewire
        krb5
        libxcb-cursor
        libxcb-wm
        libxcb-util
        libxcb-image
        libxcb-keysyms
        libxcb-render-util
      ];
    };
  };
}
