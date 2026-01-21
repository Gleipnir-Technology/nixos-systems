{ inputs, lib, pkgs, ...}:
{
	services.caddy.virtualHosts = {
		"nidus.cloud".extraConfig = ''
			root * /var/www/html/nidus.cloud
			file_server
		'';
	};
	systemd.tmpfiles.rules = [
		"d /var/www/html 0755 root root"
		"d /var/www/html/nidus.cloud 0755 caddy caddy"
	];
}
