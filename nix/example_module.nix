{ config, lib, pkgs, ... }:

let
  cfg = config.services.pigeons;
  # Works both here (nix/) and after make-flake copies this into the payload root.
  packagePath =
    if builtins.pathExists ./nix/package.nix
    then ./nix/package.nix
    else ./package.nix;
in
{
  options.services.pigeons = {
    enable = lib.mkEnableOption "pigeons SSH tunnel roost service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage packagePath { };
      defaultText = lib.literalExpression "pkgs.callPackage <package.nix> { }";
      description = "Pigeons package to install and run.";
    };

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
    environment.systemPackages = [ cfg.package ];

    environment.etc."pigeons/config.toml" = lib.mkIf (cfg.telemetryEnabled != null) {
      text = ''
        telemetry_enabled = ${lib.boolToString cfg.telemetryEnabled}
      '';
    };

    systemd.services.pigeons = {
      description = "Pigeons SSH tunnel roost service";
      after = [ "network-online.target" "sshd.service" ];
      wants = [ "network-online.target" "sshd.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " ([
          "${lib.getExe cfg.package}"
          "roost"
          "--ssh-port"
          (toString cfg.sshPort)
        ] ++ lib.optional cfg.ephemeral "--ephemeral");
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [ "RUST_LOG=info" ];
      };
    };
  };
}