{
  config,
  pkgs-unstable,
  ...
}:

{
  services.open-webui = {
    enable = true;
    package = pkgs-unstable.open-webui.overrideAttrs (old: {
      propagatedBuildInputs =
        old.propagatedBuildInputs
        ++ (
          with pkgs-unstable.python3Packages;
          [
            # Run code
            pydantic
            # Youtube transcription plugin
            yt-dlp
          ]
          ++ pkgs-unstable.open-webui.optional-dependencies.postgres
          ++ (with pkgs-unstable; [
            bash
            gvisor
            jellyfin-ffmpeg
            util-linux
          ])
        );
    });
    host = "0.0.0.0";
    port = 8090;
    openFirewall = true;
    environmentFile = config.sops.templates."open-webui/env".path;
  };

  sops.secrets = {
    "gcloud/pse_api/id" = { };
    "gcloud/pse_api/key" = { };
  };

  sops.templates."open-webui/env" = {
    mode = "0444";
    content = ''
      # general
      http_proxy="http://localhost:8888"
      https_proxy="http://localhost:8888"
      no_proxy=".${config.sops.placeholder."tailscale_api/tailnet"}"
      ENV="prod"
      WEBUI_URL="https://ai.${config.sops.placeholder."tailscale_api/tailnet"}"
      CORS_ALLOW_ORIGIN="https://ai.${config.sops.placeholder."tailscale_api/tailnet"}"
      DATABASE_URL="postgresql://open-webui@/open-webui?host=/run/postgresql"
      ENABLE_PERSISTENT_CONFIG="False"
      BYPASS_MODEL_ACCESS_CONTROL="True"
      USER_AGENT="Ananth's Open WebUI"

      # ollama api
      OLLAMA_BASE_URLS="http://enterprise.${
        config.sops.placeholder."tailscale_api/tailnet"
      }:11434;http://discovery.${config.sops.placeholder."tailscale_api/tailnet"}:11434"
      EMABLE_OPENAI_API="False"

      # auth
      ENABLE_LOGIN_FORM="False"
      ENABLE_OAUTH_PERSISTENT_CONFIG="False"
      ENABLE_SIGNUP="True"
      ENABLE_OAUTH_SIGNUP="True"
      OAUTH_UPDATE_PICTURE_ON_LOGIN="True"

      # Google OpenID
      GOOGLE_CLIENT_ID="${config.sops.placeholder."gcloud/oauth_self-hosted_clients/id"}"
      GOOGLE_CLIENT_SECRET="${config.sops.placeholder."gcloud/oauth_self-hosted_clients/secret"}"
      GOOGLE_REDIRECT_URI="https://ai.${
        config.sops.placeholder."tailscale_api/tailnet"
      }/oauth/google/callback"
      OPENID_PROVIDER_URL="https://accounts.google.com/.well-known/openid-configuration"

      # See http://github.com/open-webui/open-webui/discussions/10571
      HF_ENDPOINT=https://hf-mirror.com/ 

      # See https://github.com/nixos/nixpkgs/issues/430433
      FRONTEND_BUILD_DIR="${config.services.open-webui.stateDir}/build";
      DATA_DIR="${config.services.open-webui.stateDir}/data";
      STATIC_DIR="${config.services.open-webui.stateDir}/static";

      # web search
      ENABLE_WEB_SEARCH="True"
      WEB_SEARCH_TRUST_ENV="True"
      WEB_SEARCH_ENGINE="google_pse"
      GOOGLE_PSE_ENGINE_ID="${config.sops.placeholder."gcloud/pse_api/id"}"
      GOOGLE_PSE_API_KEY="${config.sops.placeholder."gcloud/pse_api/key"}"

      # RAG
      PDF_EXTRACT_IMAGES="True"
    '';
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "open-webui" ];
    ensureUsers = [
      {
        name = "open-webui";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
  };

  services.tsnsrv.services.ai = {
    funnel = true;
    urlParts.host = "127.0.0.1";
    urlParts.port = 8090;
  };

}
