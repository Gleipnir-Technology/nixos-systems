{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.static-websites.enable = mkEnableOption "custom static-websites configuration";

	config = mkIf config.myModules.static-websites.enable {
		services.caddy.virtualHosts."blog.tealok.tech".extraConfig = ''
			root * /var/www/blog.tealok.tech
			file_server
		'';
		users.groups.www-data = {};
		users.users.www-data = {
			group = "www-data";
			isSystemUser = true;
		};
	};
}
