packages:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (packages.${pkgs.stdenv.hostPlatform.system}) texlyre;

  cfg = config.services.texlyre;
in
{
  options = {
    services.dailissajous = {
      enable = lib.mkEnableOption "Enable the Dalissajous daily service";

      package = lib.mkOption {
        type = lib.types.package;
        default = texlyre;
        description = "Dailissajous package to use.";
      };

      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = "File containing the client secret.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        description = "User to use for the systemd service.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        description = "Group to use for the systemd service.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      # Service running the Mastodon python script
      services.dailissajous = {
        description = "Dailissajous service posting a Lissajous curve each day on Mastodon";
        wantedBy = [ ];
        wants = [ "nginx.service" ];
        after = [ "network.target" "nginx.service" ];

        # Environment vars to set for the service
        environment = {
          # Disable Python's buffering of STDOUT and STDERR
          PYTHONUNBUFFERED = "1";
        };

        # Add required packages to the path
        path = [
          pkgs.bash
          python3Env
        ];

        serviceConfig = {
          Type = "oneshot";
          # Run the script located directly in the result folder
          ExecStart = "${python3Env}/bin/python ${cfg.package}/dailissajous.py ${cfg.clientSecretFile}";

          # Security settings to prevent service from having too many priviliges
          # It doesn't need to write anywhere.
          ProtectSystem = "full";
          ProtectHome = true;
          NoNewPriviliges = true;
          RestrictSUIDSGID = true;
          DynamicUser = "yes";

          StateDirectory = "texlyre";

          User = cfg.user;
          Group = cfg.group;
        };
      };
    };
  };
}
