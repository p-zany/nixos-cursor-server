moduleConfig: {
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.windsurf-server = let
    inherit (lib) mkEnableOption mkOption;
    inherit (lib.types) lines listOf nullOr package str;
  in {
    enable = mkEnableOption "Windsurf Server";

    enableFHS = mkEnableOption "a FHS compatible environment";

    nodejsPackage = mkOption {
      type = nullOr package;
      default = null;
      example = pkgs.nodejs_20;
      description = ''
        Whether to use a specific Node.js rather than the version supplied by Windsurf server.
      '';
    };

    extraRuntimeDependencies = mkOption {
      type = listOf package;
      default = [ ];
      description = ''
        A list of extra packages to use as runtime dependencies.
        It is used to determine the RPATH to automatically patch ELF binaries with,
        or when a FHS compatible environment has been enabled,
        to determine its extra target packages.
      '';
    };

    installPath = mkOption {
      type = str;
      default = "$HOME/.windsurf-server";
      example = "$HOME/.windsurf-server-oss";
      description = ''
        The install path.
      '';
    };

    postPatch = mkOption {
      type = lines;
      default = "";
      description = ''
        Lines of Bash that will be executed after the Windsurf server installation has been patched.
        This can be used as a hook for custom further patching.
      '';
    };
  };

  config = let
    inherit (lib) mkDefault mkIf mkMerge;
    cfg = config.services.windsurf-server;
    auto-fix-windsurf-server =
      pkgs.callPackage ../../pkgs/auto-fix-windsurf-server.nix
      (removeAttrs cfg [ "enable" ]);
  in
    mkIf cfg.enable (mkMerge [
      {
        services.windsurf-server.nodejsPackage = mkIf cfg.enableFHS (mkDefault pkgs.nodejs_20);
      }
      (moduleConfig {
        name = "auto-fix-windsurf-server";
        description = "Automatically fix the Windsurf server used by the remote SSH extension";
        serviceConfig = {
          # When a monitored directory is deleted, it will stop being monitored.
          # Even if it is later recreated it will not restart monitoring it.
          # Unfortunately the monitor does not kill itself when it stops monitoring,
          # so rather than creating our own restart mechanism, we leverage systemd to do this for us.
          Restart = "always";
          RestartSec = 0;
          ExecStart = "${auto-fix-windsurf-server}/bin/auto-fix-windsurf-server";
        };
      })
    ]);
}
