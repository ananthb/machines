{ config, ... }:
{

  imports = [
    ./postgres.nix
  ];

  services = {
    grafana = {
      enable = true;
      settings = {
        database = {
          type = "postgres";
          host = "/run/postgresql";
          name = "grafana";
          user = "grafana";
        };

        server = {
          http_addr = "::";
          domain = "metrics.kedi.dev";
          root_url = "https://metrics.kedi.dev";
        };

        users = {
          allow_sign_up = false;
        };

        "auth.basic" = {
          enabled = false;
        };

        auth = {
          disable_login_form = true;
        };

        "auth.google" = {
          enabled = true;
          client_id = "$__file{${config.sops.secrets."gcloud/oauth/self-hosted_clients/id".path}}";
          client_secret = "$__file{${config.sops.secrets."gcloud/oauth/self-hosted_clients/secret".path}}";
          allow_sign_up = false;
          auto_login = true;
          skip_org_role_sync = true;
          scopes = "openid email profile";
        };
      };

      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            url = "http://localhost:8428";
            name = "VictoraMetrics";
            type = "prometheus";
            jsonData = {
              httpMethod = "POST";
              manageAlerts = true;
            };
          }
        ];
        dashboards.settings.providers = [
          {
            name = "applications";
            orgId = 1;
            folder = "Applications";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "${./grafana/dashboards/Applications}";
            };
          }
          {
            name = "infrastructure";
            orgId = 1;
            folder = "Infrastructure";
            type = "file";
            disableDeletion = false;
            editable = true;
            options = {
              path = "${./grafana/dashboards/Infrastructure}";
            };
          }
        ];
        alerting = {
          rules.settings = {
            apiVersion = 1;
            groups = [
              {
                orgId = 1;
                name = "Right About Now";
                folder = "Applications";
                interval = "30s";
                rules = [
                  {
                    uid = "dex9yo4k0n6dcb";
                    title = "Application Down";
                    condition = "C";
                    data = [
                      {
                        refId = "A";
                        relativeTimeRange = {
                          from = 600;
                          to = 0;
                        };
                        datasourceUid = "P3D437DB70E32EE8A";
                        model = {
                          disableTextWrap = false;
                          editorMode = "builder";
                          expr = "up{type=\"app\"}";
                          fullMetaSearch = false;
                          includeNullMetadata = true;
                          instant = true;
                          intervalMs = 1000;
                          legendFormat = "__auto";
                          maxDataPoints = 43200;
                          range = false;
                          refId = "A";
                          useBackend = false;
                        };
                      }
                      {
                        refId = "C";
                        datasourceUid = "__expr__";
                        model = {
                          conditions = [
                            {
                              evaluator = {
                                params = [ 1 ];
                                type = "lt";
                              };
                              operator = {
                                type = "and";
                              };
                              query = {
                                params = [ "C" ];
                              };
                              reducer = {
                                params = [ ];
                                type = "last";
                              };
                              type = "query";
                            }
                          ];
                          datasource = {
                            type = "__expr__";
                            uid = "__expr__";
                          };
                          expression = "A";
                          intervalMs = 1000;
                          maxDataPoints = 43200;
                          refId = "C";
                          type = "threshold";
                        };
                      }
                    ];
                    noDataState = "NoData";
                    execErrState = "Error";
                    for = "1m";
                    keepFiringFor = "1m";
                    annotations = {
                      summary = "A hosted application is down";
                    };
                    isPaused = false;
                    notification_settings = {
                      receiver = "grafana-default-telegram";
                      mute_time_intervals = [ "Indian Nights" ];
                    };
                  }
                ];
              }
              {
                orgId = 1;
                name = "Right About Now";
                folder = "Infrastructure";
                interval = "30s";
                rules = [
                  {
                    uid = "fexk4g07p6134a";
                    title = "Home Network Down";
                    condition = "C";
                    data = [
                      {
                        refId = "A";
                        relativeTimeRange = {
                          from = 600;
                          to = 0;
                        };
                        datasourceUid = "P3D437DB70E32EE8A";
                        model = {
                          disableTextWrap = false;
                          editorMode = "builder";
                          expr = "up{role=~\"router|server\", type=\"node\"}";
                          fullMetaSearch = false;
                          includeNullMetadata = true;
                          instant = true;
                          intervalMs = 1000;
                          legendFormat = "__auto";
                          maxDataPoints = 43200;
                          range = false;
                          refId = "A";
                          useBackend = false;
                        };
                      }
                      {
                        refId = "C";
                        datasourceUid = "__expr__";
                        model = {
                          conditions = [
                            {
                              evaluator = {
                                params = [ 1 ];
                                type = "lt";
                              };
                              operator = {
                                type = "and";
                              };
                              query = {
                                params = [ "C" ];
                              };
                              reducer = {
                                params = [ ];
                                type = "last";
                              };
                              type = "query";
                            }
                          ];
                          datasource = {
                            type = "__expr__";
                            uid = "__expr__";
                          };
                          expression = "A";
                          intervalMs = 1000;
                          maxDataPoints = 43200;
                          refId = "C";
                          type = "threshold";
                        };
                      }
                    ];
                    noDataState = "NoData";
                    execErrState = "Error";
                    for = "1m";
                    isPaused = false;
                    notification_settings = {
                      receiver = "grafana-default-telegram";
                    };
                  }
                  {
                    uid = "ff9dwibe8wqv4a";
                    title = "NUT UPS AC Power Outage";
                    condition = "C";
                    data = [
                      {
                        refId = "A";
                        relativeTimeRange = {
                          from = 600;
                          to = 0;
                        };
                        datasourceUid = "P3D437DB70E32EE8A";
                        model = {
                          editorMode = "builder";
                          expr = "network_ups_tools_input_voltage";
                          instant = true;
                          intervalMs = 1000;
                          legendFormat = "__auto";
                          maxDataPoints = 43200;
                          range = false;
                          refId = "A";
                        };
                      }
                      {
                        refId = "C";
                        datasourceUid = "__expr__";
                        model = {
                          conditions = [
                            {
                              evaluator = {
                                params = [ 200 ];
                                type = "lt";
                              };
                              operator = {
                                type = "and";
                              };
                              query = {
                                params = [ "C" ];
                              };
                              reducer = {
                                params = [ ];
                                type = "last";
                              };
                              type = "query";
                            }
                          ];
                          datasource = {
                            type = "__expr__";
                            uid = "__expr__";
                          };
                          expression = "A";
                          intervalMs = 1000;
                          maxDataPoints = 43200;
                          refId = "C";
                          type = "threshold";
                        };
                      }
                    ];
                    noDataState = "NoData";
                    execErrState = "Error";
                    for = "30s";
                    isPaused = false;
                    notification_settings = {
                      receiver = "grafana-default-telegram";
                    };
                  }
                  {
                    uid = "cf9dwz9m0fkzka";
                    title = "Ecoflow Battery AC Power Outage";
                    condition = "C";
                    data = [
                      {
                        refId = "A";
                        relativeTimeRange = {
                          from = 600;
                          to = 0;
                        };
                        datasourceUid = "P3D437DB70E32EE8A";
                        model = {
                          editorMode = "builder";
                          expr = "ecoflow_inv_ac_in_vol";
                          instant = true;
                          intervalMs = 1000;
                          legendFormat = "__auto";
                          maxDataPoints = 43200;
                          range = false;
                          refId = "A";
                        };
                      }
                      {
                        refId = "C";
                        datasourceUid = "__expr__";
                        model = {
                          conditions = [
                            {
                              evaluator = {
                                params = [ 200000 ];
                                type = "lt";
                              };
                              operator = {
                                type = "and";
                              };
                              query = {
                                params = [ "C" ];
                              };
                              reducer = {
                                params = [ ];
                                type = "last";
                              };
                              type = "query";
                            }
                          ];
                          datasource = {
                            type = "__expr__";
                            uid = "__expr__";
                          };
                          expression = "A";
                          intervalMs = 1000;
                          maxDataPoints = 43200;
                          refId = "C";
                          type = "threshold";
                        };
                      }
                    ];
                    noDataState = "NoData";
                    execErrState = "Error";
                    for = "30s";
                    isPaused = false;
                    notification_settings = {
                      receiver = "grafana-default-telegram";
                    };
                  }
                ];
              }
            ];
          };
          policies.settings = {
            apiVersion = 1;
            policies = [
              {
                orgId = 1;
                receiver = "grafana-default-telegram";
                group_by = [
                  "grafana_folder"
                  "alertname"
                ];
                group_wait = "5m";
                group_interval = "5m";
                repeat_interval = "4h";
              }
            ];
          };
          contactPoints.settings = {
            apiVersion = 1;
            contactPoints = [
              {
                orgId = 1;
                name = "grafana-default-telegram";
                receivers = [
                  {
                    uid = "aex9vvifn6ha8a";
                    type = "telegram";
                    settings = {
                      bottoken = "\"$__file{${config.sops.secrets."telegram/bot_token".path}}\"";
                      chatid = "$__file{${config.sops.secrets."telegram/chat_id".path}}";
                    };
                    disableResolveMessage = false;
                  }
                ];
              }
            ];
          };
        };
      };
    };

    postgresql = {
      enable = true;
      ensureDatabases = [ "grafana" ];
      ensureUsers = [
        {
          name = "grafana";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  sops.secrets = {
    "telegram/bot_token".owner = config.users.users.grafana.name;
    "telegram/chat_id".owner = config.users.users.grafana.name;
    # Shared OAuth secrets - mode 0444 so multiple services can read
    "gcloud/oauth/self-hosted_clients/id".mode = "0444";
    "gcloud/oauth/self-hosted_clients/secret".mode = "0444";
  };
}
