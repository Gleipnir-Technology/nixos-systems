{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.sillytavern.enable = mkEnableOption "custom sillytavern configuration";

	config = mkIf config.myModules.sillytavern.enable {
		services.caddy.virtualHosts."ai.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10050
		'';
		sops.secrets.sillytavern-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "sillytavern";
			mode = "0440";
			owner = "sillytavern";
			restartUnits = ["${backend}-sillytavern"];
			sopsFile = ../../secrets/sillytavern.env;
		};
		systemd.tmpfiles.rules = [
			"d /opt/sillytavern/config 0755 sillytavern sillytavern"
			"d /opt/sillytavern/data 0755 sillytavern sillytavern"
			"d /opt/sillytavern/extensions 0755 sillytavern sillytavern"
			"d /opt/sillytavern/plugins 0755 sillytavern sillytavern"
		];
		virtualisation.oci-containers.containers.sillytavern = {
			environmentFiles = [
				"/var/run/secrets/sillytavern-env"
			];
			image = "ghcr.io/sillytavern/sillytavern:1.13.1";
			ports = [ "127.0.0.1:10050:8000" ];
			volumes = [
				"/opt/sillytavern/config:/home/node/app/config"
				"/opt/sillytavern/data:/home/node/app/data"
				"/opt/sillytavern/extensions:/home/node/app/public/scripts/extensions/third-party"
				"/opt/sillytavern/plugins:/home/node/app/plugins"
			];
		};
		users.groups.sillytavern = {};
		users.users.sillytavern = {
			group = "sillytavern";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
