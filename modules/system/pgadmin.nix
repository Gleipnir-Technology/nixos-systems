{ config, configFiles, lib, pkgs, ... }:
with lib;

let
	cfg = config.myModules.pgadmin;
	group = "root";
	port = 10100;
	user = "root";
in {
	options.myModules.pgadmin = {
		domainName = mkOption {
			example = "staging-pgadmin.nidus.cloud";
			type = types.str;
		};
		enable = mkEnableOption "custom pgadmin configuration";
	};

	config = mkIf config.myModules.pgadmin.enable {
		services.caddy.virtualHosts."${cfg.domainName}" = {
			extraConfig = ''
				reverse_proxy {
					to http://127.0.0.1:${toString port}
					header_up X-Forwarded-Proto "https"
				}
				header / Access-Control-Allow-Origin *
			'';
		};
		services.pgadmin = {
			enable = true;
			initialEmail = "eli@gleipnir.technology";
			initialPasswordFile = "/var/run/secrets/pgadmin.yaml";
			port = port;
		};
		sops.secrets."pgadmin-initial-password-file" = {
			format = "yaml";
			group = "${group}";
			key = "initial-password";
			mode = "0440";
			owner = "${user}";
			#restartUnits = ["${nidusNameWebserver}.service"];
			sopsFile = ../../secrets/pgadmin.yaml;
		};
	};
}
