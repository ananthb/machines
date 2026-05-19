{
  pkgs,
  username,
  ...
}: {
  imports = [
    ../../services/logiops.nix

    ../../services/frigate.nix
  ];

  my-services.frigate = {
    enable = true;
    settings = {
      mqtt = {
        enabled = true;
        host = "endeavour";
      };

      detectors.ov = {
        type = "openvino";
        device = "GPU";
      };

      model = {
        path = "/openvino-model/ssdlite_mobilenet_v2.xml";
        width = 300;
        height = 300;
        input_tensor = "nhwc";
        input_pixel_format = "bgr";
        labelmap_path = "/openvino-model/coco_91cl_bkgr.txt";
      };

      detect.enabled = true;
      auth.enabled = false;
      tls.enabled = false;
      ffmpeg.hwaccel_args = "preset-vaapi";
      record.enabled = true;

      go2rtc.streams = {
        # Raw stacked streams from camera
        front_door_raw = "rtsp://10.15.17.190:554/live/ch00_0";
        front_door_raw_sub = "rtsp://10.15.17.190:554/live/ch00_1";
        # Top half: public_terrace_cam (stationary) - 2304x1296 from 2304x2592
        public_terrace_cam = "ffmpeg:front_door_raw#video=h264#raw=-filter:v crop=2304:1296:0:0";
        public_terrace_cam_sub = "ffmpeg:front_door_raw_sub#video=h264#raw=-filter:v crop=640:360:0:0";
        # Bottom half: front_door_cam (PTZ) - 2304x1296 from 2304x2592
        front_door_cam = "ffmpeg:front_door_raw#video=h264#raw=-filter:v crop=2304:1296:0:1296";
        front_door_cam_sub = "ffmpeg:front_door_raw_sub#video=h264#raw=-filter:v crop=640:360:0:360";
      };

      cameras."public_terrace_cam" = {
        detect = {
          enabled = true;
          width = 640;
          height = 360;
          fps = 5;
        };
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/public_terrace_cam";
            input_args = "preset-rtsp-restream";
            roles = ["record"];
          }
          {
            path = "rtsp://127.0.0.1:8554/public_terrace_cam_sub";
            input_args = "preset-rtsp-restream";
            roles = ["detect"];
          }
        ];
      };

      cameras."front_door_cam" = {
        detect = {
          enabled = true;
          width = 640;
          height = 360;
          fps = 5;
        };
        onvif = {
          host = "10.15.17.190";
          port = 8899;
          user = "admin";
          password = "";
        };
        ffmpeg.inputs = [
          {
            path = "rtsp://127.0.0.1:8554/front_door_cam";
            input_args = "preset-rtsp-restream";
            roles = ["record"];
          }
          {
            path = "rtsp://127.0.0.1:8554/front_door_cam_sub";
            input_args = "preset-rtsp-restream";
            roles = ["detect"];
          }
        ];
      };
    };
  };

  networking.networkmanager.enable = true;
  networking.modemmanager.enable = true;
  hardware.usb-modeswitch.enable = true;

  # System packages
  environment.systemPackages = [
    pkgs.ddcutil
    pkgs.gnome-tweaks
    # GTop GIR typelib required by the GNOME system-monitor extension; placing
    # it in systemPackages exposes it via /run/current-system/sw on the
    # gnome-shell GI_TYPELIB_PATH.
    pkgs.libgtop
    pkgs.libmbim
    pkgs.libqmi
    pkgs.logitech-udev-rules
    pkgs.modemmanager
    pkgs.modem-manager-gui
    pkgs.ppp
    pkgs.rnnoise-plugin
    pkgs.tpm2-tss
    pkgs.usb-modeswitch
  ];

  programs = {
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [username];
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    virt-manager.enable = true;
  };

  services = {
    displayManager.gdm = {
      enable = true;
    };
    desktopManager.gnome.enable = true;

    devmon.enable = true;

    fwupd.enable = true;

    gvfs = {
      enable = true;
      package = pkgs.gnome.gvfs;
    };

    ollama = {
      enable = true;
      # See https://ollama.com/library
      loadModels = [
        "llama3.2:3b"
        "deepseek-r1:1.5b"
      ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      extraConfig = {
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.quantum" = 4096;
            "default.clock.min-quantum" = 2048;
            "default.clock.max-quantum" = 8192;
          };
        };

        pipewire-pulse."92-pulse-latency" = {
          "pulse.properties" = {
            "pulse.min.req" = "4096/48000";
            "pulse.default.req" = "4096/48000";
            "pulse.min.quantum" = "4096/48000";
          };
        };

        pipewire."93-rnnoise" = {
          "context.modules" = [
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Noise Canceling Microphone";
                "media.name" = "Noise Canceling Microphone";
                "filter.graph" = {
                  nodes = [
                    {
                      type = "ladspa";
                      name = "rnnoise";
                      plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                      label = "noise_suppressor_mono";
                      control = {
                        "VAD Threshold (%)" = 50.0;
                      };
                    }
                  ];
                };
                "capture.props" = {
                  "node.name" = "capture.rnnoise_source";
                  "node.passive" = true;
                };
                "playback.props" = {
                  "node.name" = "rnnoise_source";
                  "media.class" = "Audio/Source";
                };
              };
            }
          ];
        };
      };
    };

    spice-vdagentd.enable = true;
    qemuGuest.enable = true;
    spice-webdavd.enable = true;

    udisks2.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    podman = {
      enable = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    spiceUSBRedirection.enable = true;
  };

  users.users.${username}.extraGroups = ["libvirtd"];
}
