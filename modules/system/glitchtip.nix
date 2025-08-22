{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.glitchtip.enable = mkEnableOption "custom glitchtip configuration";

	config = mkIf config.myModules.glitchtip.enable {
		services.caddy.virtualHosts."glitchtip.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10060
		'';
		services.glitchtip = {
			enable = true;
			environmentFiles = [
				"/var/run/secrets/glitchtip-env"
			];
			port = 10060;
			settings.GLITCHTIP_DOMAIN = "https://glitchtip.gleipnir.technology";
		};
		sops.secrets.glitchtip-env = {
			format = "dotenv";
			group = "glitchtip";
			mode = "0440";
			owner = "glitchtip";
			restartUnits = ["glitchtip.service"];
			sopsFile = ../../secrets/glitchtip.env;
		};
	};
}
