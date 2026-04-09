# Open WebUI — LLM inference frontend with Google OAuth.
# Connects to local Ollama instance.
{
  config,
  lib,
  pkgs,
  ...
}: let
  vs = config.vault-secrets.secrets;
in {
  imports = [
    ./gcloud-oauth.nix
    ./warp.nix
    ./monitoring/postgres.nix
  ];

  services.open-webui = {
    enable = true;
    host = "::";
    port = 8090;
    package = pkgs.open-webui.overrideAttrs (old: {
      dependencies = (old.dependencies or []) ++ [pkgs.python313Packages.psycopg2];
    });
  };

  systemd.services.open-webui = {
    partOf = ["kedi.target"];
    environment = {
      ENV = "prod";
      WEBUI_URL = lib.mkForce "https://open-webui.kedi.dev";
      CORS_ALLOW_ORIGIN = "https://open-webui.kedi.dev";
      DATABASE_URL = "postgresql://open-webui@/open-webui?host=/run/postgresql";
      ENABLE_PERSISTENT_CONFIG = "False";
      BYPASS_MODEL_ACCESS_CONTROL = "True";
      USER_AGENT = "KEDI Open WebUI";

      # proxy (warp runs on localhost:8888)
      http_proxy = "http://localhost:8888";
      https_proxy = "http://localhost:8888";
      no_proxy = "localhost,.local,.lan";

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

      # See http://github.com/open-webui/open-webui/discussions/10571
      HF_ENDPOINT = "https://hf-mirror.com/";

      # web search via local SearXNG
      ENABLE_WEB_SEARCH = "True";
      WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://localhost:8890/search?q=<query>";

      # RAG
      PDF_EXTRACT_IMAGES = "True";
    };
    # Google OAuth credentials from shared gcloud-oauth vault secret.
    # ExecStartPre+ runs as root to read vault secrets and write an env
    # file, then ExecStart sources it. We can't use EnvironmentFile=
    # because systemd evaluates it before ExecStartPre runs.
    serviceConfig = {
      ExecStartPre = [
        "+${pkgs.writeShellScript "open-webui-write-oauth-env" ''
          printf "GOOGLE_CLIENT_ID=%s\nGOOGLE_CLIENT_SECRET=%s\n" \
            "$(cat ${vs.gcloud-oauth}/client_id)" \
            "$(cat ${vs.gcloud-oauth}/client_secret)" \
            > /run/open-webui-oauth.env
        ''}"
      ];
      ExecStart = lib.mkForce (
        pkgs.writeShellScript "open-webui-start" ''
          set -a
          . /run/open-webui-oauth.env
          set +a
          exec ${config.services.open-webui.package}/bin/open-webui serve --host "::" --port 8090
        ''
      );
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

  my-services.kediTargets.open-webui = true;
}
