{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.static-websites.enable = mkEnableOption "custom static-websites configuration";

	config = mkIf config.myModules.static-websites.enable {
		services.caddy.virtualHosts = {
			"blog.tealok.tech".extraConfig = ''
				root * /var/www/html/blog.tealok.tech
				file_server
			'';
			"gleipnir.technology".extraConfig = ''
				root * /var/www/html/gleipnir.technology
				file_server
			'';
			"tealok.tech".extraConfig = ''
				root * /var/www/html/tealok.tech
				file_server
			'';
			"www.gleipnir.technology".extraConfig = ''
				root * /var/www/html/gleipnir.technology
				file_server
			'';
			"www.tealok.tech".extraConfig = ''
				root * /var/www/html/tealok.tech
				file_server
			'';
		};
	};
}
