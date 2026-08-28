{ self, inputs, ... }: {
  flake.nixosModules.locale = { config, ... }: {
    i18n.defaultLocale = config.preferences.locale;
    i18n.supportedLocales = [ "es_ES.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.preferences.locale;
      LC_IDENTIFICATION = config.preferences.locale;
      LC_MEASUREMENT = config.preferences.locale;
      LC_MONETARY = config.preferences.locale;
      LC_NAME = config.preferences.locale;
      LC_NUMERIC = config.preferences.locale;
      LC_PAPER = config.preferences.locale;
      LC_TELEPHONE = config.preferences.locale;
      LC_TIME = config.preferences.locale;
    };
    console.keyMap = config.preferences.keyboardLayout;
    services.xserver.xkb.layout = config.preferences.keyboardLayout;
  };
}
