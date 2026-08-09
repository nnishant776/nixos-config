{ config, pkgs, lib, ... }: {
  options = {
    system.settings.locale = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "en_IN";
      };
    };
  };

  config = {
    i18n.defaultLocale = config.system.settings.locale.name;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.system.settings.locale.name;
      LC_IDENTIFICATION = config.system.settings.locale.name;
      LC_MEASUREMENT = config.system.settings.locale.name;
      LC_MONETARY = config.system.settings.locale.name;
      LC_NAME = config.system.settings.locale.name;
      LC_NUMERIC = config.system.settings.locale.name;
      LC_PAPER = config.system.settings.locale.name;
      LC_TELEPHONE = config.system.settings.locale.name;
      LC_TIME = config.system.settings.locale.name;
    };
  };
}
