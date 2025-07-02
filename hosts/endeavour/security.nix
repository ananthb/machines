{ username, ... }:
{
  pam.enable = true;
  pam.rssh.enable = true;
  pam.sshAgentAuth.enable = true;
  pam.sshAgentAuth.authorizedKeysFiles = [
    "/home/${username}/.ssh/id_ed25519_sk.pub"
  ];
}
