{ config, configFiles, lib, pkgs, ... }:
with lib;

let
	dbUsername = "pgadmin";
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
			initialPasswordFile = config.sops.secrets."pgadmin-initial-password-file".path;
			port = port;
			settings = {
				# Pre-configure the database server
				Servers = {
					"1" = {
						Name = "Local nidus-sync";
						Group = "Servers";
						Host = "/run/postgresql"; # unix socket directory
						Port = 5432;
						MaintenanceDB = "postgres";
						Username = dbUsername;
						SSLMode = "prefer";
					};
				};
			};
		};
		services.postgresql = {
			ensureUsers = [{
				# Read only user for pgadmin
				ensureClauses.login = true;
				name = dbUsername;
			}];
			initialScript = pkgs.writeText "postgresql-init.sql" ''
				-- Grant connection to database
				GRANT CONNECT ON DATABASE "nidus-sync" TO ${dbUsername};

				-- Connect to the database and grant schema usage
				\c nidus-sync
				GRANT USAGE ON SCHEMA public TO ${dbUsername};

				-- Grant SELECT on all existing tables
				GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${dbUsername};

				-- GRANT SELECT on all future tables
				ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${dbUsername};
			'';
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
