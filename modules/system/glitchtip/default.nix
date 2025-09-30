{ pkgs, lib, config, ... }:
with lib;
{
	disabledModules = [ "services/web-apps/glitchtip.nix" ];
	imports = [
		./glitchtip.nix
	];
	options.myModules.glitchtip.enable = mkEnableOption "custom glitchtip configuration";

	config = mkIf config.myModules.glitchtip.enable {
		services.caddy.virtualHosts."glitchtip.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10060
		'';
		services.glitchtip = {
			enable = true;
			environment = [
				"TMPDIR=/tmp/glitchtip"
			];
			environmentFiles = [
				"/var/run/secrets/glitchtip-env"
			];
			port = 10060;
			settings.GLITCHTIP_DOMAIN = "https://glitchtip.gleipnir.technology";
			workingDirectory = "/mnt/bigdisk/glitchtip";
		};
		sops.secrets.glitchtip-env = {
			format = "dotenv";
			group = "glitchtip";
			mode = "0440";
			owner = "glitchtip";
			restartUnits = ["glitchtip.service"];
			sopsFile = ../../../secrets/glitchtip.env;
		};
		systemd.tmpfiles.rules = [
			"d /tmp/glitchtip 0755 glitchtip glitchtip 1d"
		];
	};
}
