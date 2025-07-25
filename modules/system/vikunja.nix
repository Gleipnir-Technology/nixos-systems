{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.vikunja.enable = mkEnableOption "custom vikunja configuration";

	config = mkIf config.myModules.vikunja.enable {
		services.caddy.virtualHosts."todo.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10010
		'';
		services.vikunja = {
			enable = true;
			frontendHostname = "todo.gleipnir.technology";
			frontendScheme = "https";
		};
		sops.secrets.vikunja = {
			format = "yaml";
			group = "vikunja";
			key = "";
			owner = "vikunja";
			path = "/etc/vikunja/config.yaml";
			restartUnits = [ "vikunja.service" ];
			sopsFile = ../../host/corp/secrets/vikunja.yaml;
		};
		users.groups.vikunja = {};
		users.users.vikunja = {
			group = "vikunja";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
