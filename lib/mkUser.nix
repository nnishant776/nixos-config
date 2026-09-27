{ inputs }:
let
  lib = inputs.nixpkgs.lib;
  buildUser = import ./buildUser.nix;
  flakeLib = import ./flakeLib.nix { inherit lib; };

  mkUser =
    { username
    , system ? "x86_64-linux"
    , extraModules ? [ ]
    , usersDir ? ../users
      # Standalone Home-Manager is invoked by the user, on their own machine, so
      # importing their ~/.config/home-manager/default.nix crosses no privilege
      # boundary here. The system-level path (modules/user/home-manager.nix)
      # evaluates as root and defaults this off.
    , allowLocalOverride ? true
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs flakeLib; };
      modules = [
        (buildUser {
          inherit pkgs lib username extraModules usersDir allowLocalOverride;
        })
      ];
    };

  # Hostname of the machine doing the evaluation (impure: needs --impure).
  # Absent on Darwin, so this is best-effort — it only decides which host's users
  # get the bare `<username>` alias. The `<username>@<host>` keys always exist,
  # so a failed lookup is never fatal.
  currentHost =
    let
      fromFile =
        if builtins.pathExists "/etc/hostname"
        then lib.trim (builtins.readFile "/etc/hostname")
        else "";
    in
      if fromFile != "" then fromFile else builtins.getEnv "HOSTNAME";

  # Every home-manager-enabled user declared by any host, as flat entries.
  hostUserEntries = { hostConfigs, hostPlatforms }:
    lib.flatten (lib.mapAttrsToList (dirName: hostCfg:
      let
        allUsers = [ hostCfg.config.conf.host.adminUser ] ++ hostCfg.config.conf.host.extraUsers;
        enabledUsers = builtins.filter (u: u.enableHomeManager) allUsers;
      in
        map (u: {
          username = u.name;
          userCfg = u;
          system = hostPlatforms.${dirName};
          hostName = hostCfg.config.conf.host.name;
          inherit dirName;
        }) enabledUsers
    ) hostConfigs);

  entryToUser = usersDir: e:
    mkUser {
      inherit usersDir;
      inherit (e) username system;
      extraModules = [ e.userCfg.extraHomeConfig ];
      # allowLocalOverride stays at mkUser's default of true: everything built
      # here is standalone Home-Manager, run by the user on their own machine.
    };

  # Users declared by host configurations.
  #
  # Two keys per user:
  #   <username>@<host-dir>  always present, host-explicit, no hostname lookup
  #   <username>             only for hosts matching the running machine
  #
  #   home-manager switch --flake .#<username> --impure
  #   home-manager switch --flake .#<username>@<host> --impure
  discoverHostUsers = { hostConfigs, hostPlatforms, usersDir ? ../users }:
    let
      entries = hostUserEntries { inherit hostConfigs hostPlatforms; };
      localEntries = builtins.filter (e:
        e.hostName == currentHost || e.dirName == currentHost
      ) entries;
      keyed = key: es: lib.listToAttrs (map (e: lib.nameValuePair (key e) (entryToUser usersDir e)) es);
    in
      (keyed (e: "${e.username}@${e.dirName}") entries) // (keyed (e: e.username) localEntries);

  # Standalone users defined in ./users/<username>/, for users that no host
  # declares. A directory under ./users/ implicitly enables home-manager.
  # The module itself is imported by lib/buildUser.nix, which both entry points
  # share, so nothing needs passing through here.
  discoverStandaloneUsers = { usersDir ? ../users }:
    let
      userNames =
        if builtins.pathExists usersDir
        then builtins.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir usersDir))
        else [ ];
    in
      lib.genAttrs userNames (username: mkUser { inherit username usersDir; });

  # Host-declared users win on name collision: their entry carries the right
  # system and extraHomeConfig, and users/<name>/ is applied to them anyway.
  mkHomeConfigurations = { hostConfigs, hostPlatforms, usersDir ? ../users }:
    (discoverStandaloneUsers { inherit usersDir; })
    // (discoverHostUsers { inherit hostConfigs hostPlatforms usersDir; });

in {
  inherit mkUser discoverHostUsers discoverStandaloneUsers mkHomeConfigurations;
  __functor = self: self.mkUser;
}
