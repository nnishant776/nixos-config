{ config, pkgs, ... }:
let
  basePackages = with pkgs; [
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

in {
  config = {
    environment.sessionVariables = {
      PATH = [ "/usr/local/bin" "/usr/bin" "/opt/bin" ];
    };

    # Include base packages
    environment.systemPackages = with pkgs; [
      bash
    ] ++ basePackages;

    programs.nix-index.enable = true;

    # Enable nix-ld for precompiled dynamic binary execution
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; basePackages ++ [
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
        coreutils
        pciutils
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
