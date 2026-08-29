{ config, pkgs, lib, ... }: {
  config = {
    i18n.defaultLocale = config.conf.host.locale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.conf.host.locale;
      LC_IDENTIFICATION = config.conf.host.locale;
      LC_MEASUREMENT = config.conf.host.locale;
      LC_MONETARY = config.conf.host.locale;
      LC_NAME = config.conf.host.locale;
      LC_NUMERIC = config.conf.host.locale;
      LC_PAPER = config.conf.host.locale;
      LC_TELEPHONE = config.conf.host.locale;
      LC_TIME = config.conf.host.locale;
    };
  };
}
