{ pkgs, lib, config, ... }:
with lib;

let
	qgis = pkgs.qgis.override { withServer = true; };
in
{
	options.myModules.qgis.enable = mkEnableOption "custom qgis configuration";

	config = mkIf config.myModules.qgis.enable {
		environment.systemPackages = [
			qgis
			pkgs.spawn_fcgi
		];
		services.caddy = {
			#enable = true;
			#package = pkgs.caddy.withPlugins {
    				#plugins = [ "github.com/aksdb/caddy-cgi@v2.2.6" ];
				#hash = "sha256-pkq0PIdd4+uSyjXf24rDR6hfVVEg4YMBF6cS38W1vsA=";
			#};
			virtualHosts."gis.nidus.cloud".extraConfig = ''
				route {
					# Add trailing slash for directory requests
					# This redirection is automatically disabled if "{http.request.uri.path}/index.php"
					# doesn't appear in the try_files list
					#@canonicalPath {
						#file {path}/index.php
						#not path */
					#}
					#redir @canonicalPath {http.request.orig_uri.path}/ 308

					# If the requested file does not exist, try index files and assume index.php always exists
					#@indexFiles file {
						#try_files {path} {path}/index.php index.php
						#try_policy first_exist_fallback
						#split_path .php
					#}
					#rewrite @indexFiles {file_match.relative}

					# Proxy PHP files to the FastCGI responder
					#@phpFiles path *.php
					reverse_proxy * unix//var/run/qgisserver.socket {
						transport fastcgi {
						}
					}
				}
			'';
		};
	};
}
