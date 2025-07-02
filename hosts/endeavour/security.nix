{ username, ... }:
{
  pam.sshAgentAuth.enable = true;
  pam.services.${username}.sshAgentAuth = true;
  pam.rssh.enable = true;
}
