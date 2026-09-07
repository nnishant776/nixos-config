{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
  ];
}
