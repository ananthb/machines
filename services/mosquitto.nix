_: {
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        address = "0.0.0.0";
        users = {};
        settings.allow_anonymous = true;
      }
      {
        port = 1883;
        address = "::";
        users = {};
        settings.allow_anonymous = true;
      }
    ];
  };
}
