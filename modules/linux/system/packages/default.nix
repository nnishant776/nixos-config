{ inputs, config, pkgs, lib, ... }: {
  # Import package definitions
  imports = [
    ./development.nix
    ./fonts.nix
    ./multimedia.nix
    ./containerisation.nix
    ./virtualisation.nix
  ];

  options = {
    system.packages.base = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        # Core Tools
        neovim
        gnumake
        git
        curl
        file
        which
        tree

        # System Monitoring
        procs
        btop
        dust
        ncdu

        # Archives
        zip
        xz
        zstd
        unzipNLS
        p7zip
        gnutar

        # Text Processing
        gnugrep
        gawk
        gnused
        jq
        yq-go

        # Search
        fzf
        fd
        findutils
        (ripgrep.override { withPCRE2 = true; })

        # Networking Tools
        gping
        dnsutils
        wget
        curl
        aria2
        socat
        nmap
        iperf3
        tcpdump

        # File transfer
        rsync

        # Security
        libargon2
        openssl
      ];
    };
  };

  config = {
    # Enable nix experimental features
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.sessionVariables = {
      PATH = [ "/usr/local/bin" "/usr/bin" "/opt/bin" ];
    };

    # Include mandatory packages by default
    environment.systemPackages = with pkgs; [
      bash
    ] ++ ( config.system.packages.base );

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "vscode"
      "slack"
      "antigravity"
    ];

    programs.nix-index.enable = true;

    # Enable nix-ld to enable precompiled binary execution
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # List by default
        zlib
        zstd
        stdenv.cc.cc
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd

        # My own additions
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

        # Required
        glib
        libGL
        libva

        # Inspired by steam
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/st/steam/package.nix#L36-L85
        networkmanager
        vulkan-loader
        libgbm
        libdrm
        libxcrypt
        coreutils
        pciutils
        zenity
        # glibc_multi.bin # Seems to cause issue in ARM

        # # Without these it silently fails
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
        # Only libraries are needed from those two
        libudev0-shim

        # needed to run unity
        gtk3
        icu
        libnotify
        gsettings-desktop-schemas
        # https://github.com/NixOS/nixpkgs/issues/72282
        # https://github.com/NixOS/nixpkgs/blob/2e87260fafdd3d18aa1719246fd704b35e55b0f2/pkgs/applications/misc/joplin-desktop/default.nix#L16
        # log in /home/leo/.config/unity3d/Editor.log
        # it will segfault when opening files if you don’t do:
        # export XDG_DATA_DIRS=/nix/store/0nfsywbk0qml4faa7sk3sdfmbd85b7ra-gsettings-desktop-schemas-43.0/share/gsettings-schemas/gsettings-desktop-schemas-43.0:/nix/store/rkscn1raa3x850zq7jp9q3j5ghcf6zi2-gtk+3-3.24.35/share/gsettings-schemas/gtk+3-3.24.35/:$XDG_DATA_DIRS
        # other issue: (Unity:377230): GLib-GIO-CRITICAL **: 21:09:04.706: g_dbus_proxy_call_sync_internal: assertion 'G_IS_DBUS_PROXY (proxy)' failed

        # Verified games requirements
        libxt
        libxmu
        libogg
        libvorbis
        SDL
        SDL2_image
        glew_1_10
        libidn
        tbb

        # Other things from runtime
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
        # libappindicator-gtk2
        # libdbusmenu-gtk2
        # libindicator-gtk2
        libcaca
        libcanberra
        libgcrypt
        libvpx
        librsvg
        libxft
        libvdpau
        # ...
        # Some more libraries that I needed to run programs
        pango
        cairo
        atk
        gdk-pixbuf
        fontconfig
        freetype
        dbus
        alsa-lib
        expat
        # for blender
        libxkbcommon

        libxcrypt-legacy # For natron
        libGLU # For natron

        # Appimages need fuse, e.g. https://musescore.org/fr/download/musescore-x86_64.AppImage
        fuse
        e2fsprogs

        # darktable nightly AppImage https://github.com/darktable-org/darktable/releases
        gmp

        # RapidRaw
        harfbuzz
        libgpg-error
        # https://github.com/xournalpp/xournalpp/releases/download/v1.2.4/xournalpp-1.2.4-x86_64.AppImage
        fribidi
        librsvg
        # https://github.com/nix-community/nix-ld/issues/95#issuecomment-3041993870
        (runCommand "librsvg" {} ''
          mkdir -p $out/lib/gdk-pixbuf-2.0/2.10.0/loaders
        ln -s "${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader_svg.so" "$out/lib/libpixbufloader-svg.so"
        '')

        # pdfmastereditor
        sane-backends
        pkcs11helper

        # Qt6 requires this (e.g. used in zxlive)
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
