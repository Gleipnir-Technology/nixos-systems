{ config, configPath, lib, pkgs, ... }:

{
	options.myModules.taiga.enable = mkEnableOption "custom taiga configuration";

	config = mkIf config.myModules.taiga.enable {
		services.postgresql = {
			ensureDatabases = [ "taiga" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "taiga";
			}];
		};
		# Define the container as a systemd service
		virtualisation.oci-containers = {
			backend = "docker"; # or "podman"
			
			containers = {
				taiga-back = {
					image = "taigaio/taiga-back:6.9.0";
					
					# Environment variables
					environment = {
						POSTGRES_HOST = "postgres";
						POSTGRES_DB = "taiga";
						TAIGA_SECRET_KEY = "your-secret-key-here";
						TAIGA_SITES_DOMAIN = "taiga.example.com";
					};
					
					# Port mappings
					ports = [
						"8000:8000"
					];
					
					# Volumes
					volumes = [
						"/var/lib/taiga/media:/taiga-back/media"
						"/var/lib/taiga/static:/taiga-back/static"
					];
					
					# Auto-start on boot
					autoStart = true;
					
					# Extra options
					#extraOptions = [
						#"--network=taiga-net"
					#];
				};
			};
		};

		# Ensure the data directories exist
		systemd.tmpfiles.rules = [
			"d /var/lib/taiga 0755 root root -"
			"d /var/lib/taiga/media 0755 root root -"
			"d /var/lib/taiga/static 0755 root root -"
		];
	};
}
