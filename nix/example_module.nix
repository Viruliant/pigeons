{ config, lib, pkgs, unstable ? pkgs, ... }:
/*

in your configuration.nix set: also make sure unstable is
available it will default to regular pkgs which might be
unstable depending upon your config

{ imports = [ ./flake_pigeons/pigeons.nix ]; }

Check the service is healthy with

systemctl status pigeons.service.

On the target machine prints the Roost ID with:

    cat /etc/pigeons/endpoint_id

or
    pigeons service status

That last one also prints a ready-made pigeons add command.

On the machine you want to connect from

```
pigeons add --id <ROOST_ID> --name target_machine
pigeons list
ssh some_user@target_machine
```

`pigeons add` writes a `Host target_machine` entry into
`~/.ssh/config` with 
`ProxyCommand pigeons fly --stdio <ROOST_ID>`,
so the final ssh is a normal SSH login using a user that exists 
on the roost (`some_user` in this config).

One-off equivalent without saving a route:

    ssh -o ProxyCommand="pigeons fly --stdio <ROOST_ID>" some_user@target_machine

Note: pigeons paths shows your local pigeon key paths, not the 
roost's endpoint ID = use pigeons service status` on the roost 
for that.

*/

let
  cfg = config.services.pigeons;
  package =
    if builtins.pathExists ./nix/package.nix then
      pkgs.callPackage ./nix/package.nix { }
    else if builtins.pathExists ./package.nix then
      pkgs.callPackage ./package.nix { }
    else if unstable ? pigeons then
      unstable.pigeons # confirmed working
    else if pkgs ? pigeons then
      pkgs.pigeons
    else
      throw "pigeons package not found";
in {
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
    # v0.2.1 roost requires a local sshd on cfg.sshPort.
    services.openssh.enable = lib.mkDefault true;
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
        # v0.2.1 reads $XDG_CONFIG_HOME/pigeons/config.toml; /etc points it at /etc/pigeons/config.toml.
        Environment = [ "RUST_LOG=info" "XDG_CONFIG_HOME=/etc" ];
        # Newer pigeons reads /etc/pigeons/config.toml directly:
        # Environment = [ "RUST_LOG=info" ];
      };
    };
  };
}