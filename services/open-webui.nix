# Open WebUI — LLM inference frontend with Google OAuth.
# Connects to local Ollama instance.
{config, ...}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    ./warp.nix
    ./monitoring/postgres.nix
  ];

  services.open-webui = {
    enable = true;
    host = "::";
    port = 8090;
    environmentFile = "${vs.open-webui}/environment";
  };

  # Non-secret env vars set directly on the service
  systemd.services.open-webui = {
    partOf = ["kedi.target"];
    environment = {
      ENV = "prod";
      WEBUI_URL = "https://open-webui.kedi.dev";
      CORS_ALLOW_ORIGIN = "https://open-webui.kedi.dev";
      DATABASE_URL = "postgresql://open-webui@/open-webui?host=/run/postgresql";
      ENABLE_PERSISTENT_CONFIG = "False";
      BYPASS_MODEL_ACCESS_CONTROL = "True";
      USER_AGENT = "KEDI Open WebUI";

      # ollama
      OLLAMA_BASE_URLS = "http://localhost:11434";
      ENABLE_OPENAI_API = "False";

      # auth
      ENABLE_API_KEYS = "True";
      ENABLE_LOGIN_FORM = "False";
      ENABLE_OAUTH_PERSISTENT_CONFIG = "False";
      ENABLE_SIGNUP = "True";
      ENABLE_OAUTH_SIGNUP = "True";
      OAUTH_UPDATE_PICTURE_ON_LOGIN = "True";
      GOOGLE_REDIRECT_URI = "https://open-webui.kedi.dev/oauth/google/callback";
      OPENID_PROVIDER_URL = "https://accounts.google.com/.well-known/openid-configuration";

      # web search
      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_TRUST_ENV = "True";
      WEB_SEARCH_ENGINE = "google_pse";

      # RAG
      PDF_EXTRACT_IMAGES = "True";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = ["open-webui"];
    ensureUsers = [
      {
        name = "open-webui";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  # Secrets from Vault: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET,
  # GOOGLE_PSE_ENGINE_ID, GOOGLE_PSE_API_KEY, http_proxy, https_proxy, no_proxy
  vault-secrets.secrets.open-webui = {
    services = ["open-webui"];
  };

  my-services.kediTargets.open-webui = true;
}
