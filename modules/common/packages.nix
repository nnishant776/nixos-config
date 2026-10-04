# The package set every machine gets, on either platform.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    bash

    # Core tools
    (coreutils-full.override { withPrefix = false; })
    gettext
    neovim
    gnumake
    git
    curl
    file
    which
    tree
    tmux
    util-linux

    # System monitoring
    procs
    btop
    dust
    ncdu
    pciutils

    # Archives
    zip
    xz
    zstd
    zlib
    unzipNLS
    p7zip
    gnutar

    # Text processing
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

    # Networking tools
    gping
    dnsutils
    wget
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
}
