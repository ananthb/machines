# Intel GPU hardware acceleration (VAAPI/QSV).
# Used by Immich, Jellyfin, and Frigate for hardware transcoding.
{pkgs, ...}: {
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };
  hardware.graphics = {
    enable = true;
    extraPackages = [
      pkgs.intel-media-driver
      pkgs.intel-vaapi-driver
      pkgs.intel-ocl
      pkgs.libva-vdpau-driver
      pkgs.libvdpau-va-gl
      pkgs.intel-compute-runtime # OpenCL (hardware tonemapping and subtitle burn-in)
      pkgs.vpl-gpu-rt # QSV on 11th gen or newer
    ];
  };
}
