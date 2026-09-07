{ inputs }:
let
  lib = inputs.nixpkgs.lib;
  buildUser = import ./buildUser.nix;
  mkUser =
    { username
    , system ? "x86_64-linux"
    , userModules ? []
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        (buildUser {
          inherit pkgs lib username;
        })
      ] ++ userModules;
    };

  # Discovers enabled users from host configurations.
  #
  # Uses builtins.getHostname (impure) to match the current machine against
  # conf.host.name or the host directory name (both case-sensitive), then
  # exposes only the users that belong to *this* host.
  #
  # Keys are plain usernames so the switch command stays clean:
  #   home-manager switch --flake .#<username> --impure
  discoverHostUsers = { hostConfigs, hostPlatforms }:
    let
      currentHost = builtins.replaceStrings ["\n"] [""] (builtins.readFile "/etc/hostname");

      # Flatten all (dirName, hostCfg, user) triples across every host
      allEntries = lib.flatten (lib.mapAttrsToList (dirName: hostCfg:
        let
          allUsers    = [ hostCfg.config.conf.host.adminUser ] ++ hostCfg.config.conf.host.extraUsers;
          enabledUsers = builtins.filter (u: u.enableHomeManager) allUsers;
          system      = hostPlatforms.${dirName};
          hostName    = hostCfg.config.conf.host.name;
        in
          map (u: {
            username = u.name;
            userCfg  = u;
            inherit system hostName dirName;
          }) enabledUsers
      ) hostConfigs);

      # Keep only entries whose host matches the running machine (case-sensitive)
      currentEntries = builtins.filter (e:
        e.hostName == currentHost || e.dirName == currentHost
      ) allEntries;

      usernames = lib.unique (map (e: e.username) currentEntries);
    in
      lib.genAttrs usernames (username:
        let
          entry = builtins.head (builtins.filter (e: e.username == username) currentEntries);
        in
          mkUser {
            username    = username;
            system      = entry.system;
            userModules = [ (entry.userCfg.extraHomeConfig or {}) ];
          }
      );

  # Discovers standalone users defined in ./users/<username>/default.nix.
  # A directory under ./users/ implicitly enables home-manager for that user.
  # The base config in modules/user/ and ~/.config/home-manager/default.nix are
  # merged automatically via lib/buildUser.nix; default.nix here is for any
  # additional user-specific modules on top.
  # These are host-agnostic and always present regardless of current hostname.
  discoverStandaloneUsers = { usersDir ? ../users }:
    let
      hasUsersDir = builtins.pathExists usersDir;
      userNames   = if hasUsersDir then builtins.attrNames (
        lib.filterAttrs (_: t: t == "directory") (builtins.readDir usersDir)
      ) else [];
    in
      lib.genAttrs userNames (u:
        let
          userPath   = usersDir + "/${u}/default.nix";
          userModule = if builtins.pathExists userPath then [ (import userPath) ] else [];
        in
          mkUser {
            username    = u;
            userModules = userModule;
          }
      );

  mkHomeConfigurations = { hostConfigs, hostPlatforms, usersDir ? ../users }:
    (discoverHostUsers { inherit hostConfigs hostPlatforms; })
    // (discoverStandaloneUsers { inherit usersDir; });

in {
  inherit mkUser discoverHostUsers discoverStandaloneUsers mkHomeConfigurations;
  __functor = self: self.mkUser;
}
