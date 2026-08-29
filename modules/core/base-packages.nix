{ pkgs }:

with pkgs; [
  # Core Tools
  (coreutils-full.override { withPrefix = false; })
  neovim
  gnumake
  git
  curl
  file
  which
  tree
  tmux
  util-linux

  # System Monitoring
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
]
