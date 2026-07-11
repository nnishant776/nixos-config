{ config, pkgs, lib, ... }: {
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

    # Include mandatory packages by default
    environment.systemPackages = with pkgs; [
      bash
    ] ++ ( config.system.packages.base );
  };
}
