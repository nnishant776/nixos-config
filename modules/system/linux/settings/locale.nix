{ config, pkgs, lib, ... }: {
  config = {
    i18n.defaultLocale = config.myconf.host.locale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.myconf.host.locale;
      LC_IDENTIFICATION = config.myconf.host.locale;
      LC_MEASUREMENT = config.myconf.host.locale;
      LC_MONETARY = config.myconf.host.locale;
      LC_NAME = config.myconf.host.locale;
      LC_NUMERIC = config.myconf.host.locale;
      LC_PAPER = config.myconf.host.locale;
      LC_TELEPHONE = config.myconf.host.locale;
      LC_TIME = config.myconf.host.locale;
    };
  };
}
