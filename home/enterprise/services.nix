_: {
  services = {
    activitywatch.enable = true;
    gnome-keyring = {
      enable = true;
      # Avoid gnome-keyring's SSH agent since it can't sign FIDO sk keys reliably.
      components = [
        "pkcs11"
        "secrets"
      ];
    };
    # Use OpenSSH's agent for FIDO/U2F sk keys.
    ssh-agent.enable = true;
  };
}
