{ pkgs }:

with pkgs; [
  # Core Tools
  neovim
  gnumake
  git
  curl
  file
  which
  tree
  tmux

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
