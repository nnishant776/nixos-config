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
      # Home Manager is invoked by the user, on their own machine, so importing
      # their ~/.config/home-manager/default.nix crosses no privilege boundary.
      # The parameter defaults off in buildUser so that any future system-level
      # caller — which would evaluate as root — has to opt in deliberately.
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

  # Every home-manager-enabled user declared by any host, as flat entries.
  hostUserEntries = { hostConfigs, hostPlatforms }:
    lib.flatten (lib.mapAttrsToList (dirName: hostCfg:
      let
        host = hostCfg.config.conf.host;
        # Only users granted allowHomeManagement. Organisation-managed homes are
        # activated by the system (modules/user/home-manager.nix) and must not
        # also be published here, or both generations would fight over the same
        # home directory. conf.host.enableHomeManager gates the whole host.
        enabledUsers = lib.filterAttrs
          (_: u: host.enableHomeManager && u.allowHomeManagement)
          host.users;
      in
        lib.mapAttrsToList (username: u: {
          inherit username;
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

  # Users declared by host configurations, keyed `<username>@<host-dir>`.
  #
  #   home-manager switch --flake /etc/nixos#<username>@<host>
  #
  # There is deliberately no bare `<username>` alias. Resolving one meant
  # reading /etc/hostname at evaluation time, which made these outputs impure,
  # did not work on Darwin (no such file), and failed badly: in pure mode the
  # alias did not error, it silently did not exist, so `--flake .#admin` came
  # back "does not provide attribute" with nothing to explain why.
  #
  # The hostname is a property of the machine running the command, so the
  # `home-switch` wrapper resolves it in the shell instead.
  discoverHostUsers = { hostConfigs, hostPlatforms, usersDir ? ../users }:
    let
      entries = hostUserEntries { inherit hostConfigs hostPlatforms; };
      keyed = key: es: lib.listToAttrs (map (e: lib.nameValuePair (key e) (entryToUser usersDir e)) es);
    in
      keyed (e: "${e.username}@${e.dirName}") entries;

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
