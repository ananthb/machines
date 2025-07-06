{
  enable = true;
  publicKeys = [ ];
  settings = {
    use-agent = true;
  };

  scdaemonSettings = {
    disable-ccid = true;
    reader-port = "Yubico Yubi";
  };
}
