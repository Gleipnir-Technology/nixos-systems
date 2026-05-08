{ config, configFiles, lib, pkgs, ... }:
with lib;

let
	databaseName = "nidus-sync";
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
						Name = "Local ${databaseName}";
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
		};
		systemd.services.pgadmin-setup-permissions = {
			description = "Setup read-only permissions for pgadmin user";
			after = [ "postgresql.service" ];
			requires = [ "postgresql.service" ];
			wantedBy = [ "multi-user.target" ];
        
			serviceConfig = {
				Type = "oneshot";
				User = "postgres";
				RemainAfterExit = true;
			};
        
			script = ''
				${config.services.postgresql.package}/bin/psql -d ${databaseName} << 'EOF'
				-- Grant connection to database
				GRANT CONNECT ON DATABASE ${databaseName} TO pgadmin;
				
				-- Dynamically grant permissions on all non-system schemas
				DO $$
				DECLARE
				    schema_name text;
				BEGIN
				    FOR schema_name IN 
					SELECT nspname 
					FROM pg_namespace 
					WHERE nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
					AND nspname NOT LIKE 'pg_temp%'
					AND nspname NOT LIKE 'pg_toast_temp%'
				    LOOP
					EXECUTE format('GRANT USAGE ON SCHEMA %I TO pgadmin', schema_name);
					EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO pgadmin', schema_name);
					EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA %I TO pgadmin', schema_name);
					EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO pgadmin', schema_name);
				    END LOOP;
				END $$;
				EOF
			'';
        
			# This ensures the service runs again when you deploy changes
			restartTriggers = [ 
				config.services.postgresql.package
				"${databaseName}"
			];
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
