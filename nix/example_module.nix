{ config, lib, pkgs, ... }:

let
  cfg = config.services.pigeons;
  # Load the package from ./flake_pigeons next to configuration.nix
  pigeonsFlake = builtins.getFlake (toString ./flake_pigeons);
  pigeonsPkg = pigeonsFlake.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.services.pigeons = {
    enable = lib.mkEnableOption "pigeons SSH tunnel roost service";

    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 22;
      description = "Local SSH daemon port to proxy connections to.";
    };

    ephemeral = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use a throwaway identity instead of persistent keys.";
    };

    telemetryEnabled = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Set telemetry_enabled in /etc/pigeons/config.toml when non-null.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pigeonsPkg ];

    environment.etc."pigeons/config.toml" = lib.mkIf (cfg.telemetryEnabled != null) {
      text = ''
        telemetry_enabled = ${lib.boolToString cfg.telemetryEnabled}
      '';
    };

    systemd.services.pigeons = {
      description = "Pigeons SSH tunnel roost service";
      after = [ "network-online.target" "sshd.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " ([
          "${lib.getExe pigeonsPkg}"
          "roost"
          "--ssh-port"
          (toString cfg.sshPort)
        ] ++ lib.optional cfg.ephemeral "--ephemeral");
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}