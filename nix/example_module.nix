{ config, lib, pkgs, unstable, ... }:

# { imports = [ ./flake_pigeons/pigeons.nix ]; }
let
  cfg = config.services.pigeons;
  package =
    if builtins.pathExists ./nix/package.nix then
      pkgs.callPackage ./nix/package.nix { }
    else if builtins.pathExists ./package.nix then
      pkgs.callPackage ./package.nix { }
    else if unstable ? pigeons then
      unstable.pigeons
    else if pkgs ? pigeons then
      pkgs.pigeons
    else
      throw "pigeons package not found";
in

{
  options.services.pigeons = {
    enable = lib.mkEnableOption "pigeons SSH tunnel roost service" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      defaultText = lib.literalExpression ''
        pkgs.callPackage ./nix/package.nix { }
        or pkgs.callPackage ./package.nix { }
        or pkgs.unstable.pigeons
      '';
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
      type = lib.types.bool;
      default = false;
#       type = lib.types.nullOr lib.types.bool;
#       default = null;
      description = "Set telemetry_enabled in /etc/pigeons/config.toml when non-null.";
    };

  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

#     environment.etc."pigeons/config.toml" = lib.mkIf (cfg.telemetryEnabled != null) {
    environment.etc."pigeons/config.toml" = {
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