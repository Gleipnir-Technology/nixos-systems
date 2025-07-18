{ config, lib, pkgs, configPath, ... }:

with lib;

{
	options.myModules.caddy.enable = mkEnableOption "custom caddy configuration";

	config = mkIf config.myModules.caddy.enable {
		security.acme = {
			acceptTerms = true;
			defaults.email = "eli@gleipnir.technology";
		};
		services.caddy = {
			enable = true;
			logFormat = ''
				level WARN
			'';
		};
	};
}
