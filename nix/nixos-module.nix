packages:
{
  config,
  lib,
  stdenv,
  nodejs,
  ...
}:

let
  inherit (packages.${stdenv.hostPlatform.system}) texlyre;

  cfg = config.services.texlyre;
in
{
  options = {
    services.dailissajous = {
      enable = lib.mkEnableOption "Enable the TexLyre service";

      package = lib.mkOption {
        type = lib.types.package;
        default = texlyre;
        description = "TexLyre package to use.";
      };

      clientSecretFile = lib.mkOption {
        type = lib.types.path;
        description = "File containing the client secret.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "texlyre";
        description = "User to use for the systemd service.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "texlyre";
        description = "Group to use for the systemd service.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      # Service running the Mastodon python script
      services.texlyre = {
        description = "daemon for services around a TexLyre instance, a local first collaborative LaTeX/Typst web service";
        wantedBy = [ "multi-user.target" ];
        wants = [ "nginx.service" ];
        after = [
          "network.target"
          "nginx.service"
        ];

        # Environment vars to set for the service
        environment = {
        };

        # Add required packages to the path
        path = [
          nodejs
        ];

        serviceConfig = {
          Type = "notify";
          # Run the script located directly in the result folder
          ExecStart = ""; # TODO

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
