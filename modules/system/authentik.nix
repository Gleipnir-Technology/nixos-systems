{ config, lib, pkgs, ... }:
with lib;
{
	options.myModules.authentik.enable = mkEnableOption "custom authentik configuration";

	config = mkIf config.myModules.authentik.enable {
		environment.systemPackages = [
			pkgs.authentik
		];
		services.authentik = {
			enable = true;
			environmentFile = "/run/secrets/authentik-env";
			settings = {
				database = {
					host = "127.0.0.1";
					name = "authentik";
				};
				email = {
					host = "smtp.forwardemail.net";
					port = 2465;
					use_tls = false;
					use_ssl = true;
					from = "auth@corp.gleipnir.technology";
				};
				listen = {
					listen_debug = "127.0.0.1:9900";
					listen_debug_py = "127.0.0.1:9901";
					listen_http = "127.0.0.1:9000";
					listen_https = "127.0.0.1:9443";
					listen_ldap = "127.0.0.1:3389";
					listen_ldaps = "127.0.0.1:6636";
					listen_radius = "127.0.0.1:1812";
					listen_metrics = "127.0.0.1:9300";
				};
			};
		};
		services.caddy.virtualHosts."auth.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:9000
		'';
		services.postgresql = {
			ensureDatabases = [ "authentik" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "authentik";
			}];
		};
		sops.secrets.authentik-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "authentik";
			mode = "0440";
			owner = "authentik";
			restartUnits = ["authentik" "authentik-migrate" "authentik-worker"];
			sopsFile = ../../secrets/authentik.env;
		};
		systemd.tmpfiles.rules = [
			"d /opt/authentik/certs 0755 authentik authentik"
			"d /opt/authentik/media 0755 authentik authentik"
			"d /opt/authentik/templates 0755 authentik authentik"
		];
		users.groups.authentik = {};
		users.users.authentik = {
			group = "authentik";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
