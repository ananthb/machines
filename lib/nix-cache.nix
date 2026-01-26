# Shared Nix binary cache configuration
# The public key below must match the signing key in secrets.yaml at harmonia/signing-key
# Generate a keypair with: nix-store --generate-binary-cache-key endeavour-cache /path/to/secret /path/to/public
{
  cacheHost = "endeavour";
  cachePort = 5000;
  publicKey = "endeavour-cache:mgAcuB1qjaWHWJM7/OoRXlAUN2vVN0QYwb7GlbDo4+s=";
}
