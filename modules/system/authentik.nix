{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.authentik.enable = mkEnableOption "custom authentik configuration";

	config = mkIf config.myModules.authentik.enable {
		sops.secrets.authentik-env = {
			format = "env";
			group = "authentik";
			mode = "0440";
			owner = "authentik";
			restartUnits = ["authentik"];
			sopsFile = ../../secrets/authentik.env;
		};
		users.groups.authentik = {};
		users.users.authentik = {
			group = "authentik";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
