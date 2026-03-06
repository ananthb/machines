_: {
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        address = "::";
        users = { };
        settings.allow_anonymous = true;
      }
    ];
  };
}
