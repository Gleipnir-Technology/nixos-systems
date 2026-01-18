{ pkgs, lib, config, ... }:
with lib;
let
	group = "twenty_crm";
	port = "10090";
	tag = "v1.8.2";
	user = "twenty_crm";
in {
	options.myModules.twenty-crm.enable = mkEnableOption "custom twenty-crm configuration";

	config = mkIf config.myModules.twenty-crm.enable {
		services.caddy.virtualHosts."crm.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:${port}
		'';
		services.postgresql = {
			ensureDatabases = [ user ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = user;
			}];
		};
		services.redis.servers.twenty-crm = {
			bind = "10.88.0.1";
			enable = true;
			port = 6379;
			requirePass = "letmein";
			user = user;
		};
		services.restic.backups."twenty-crm-db" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump ${user}"
			];
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag database"
			];
			passwordFile = "/var/run/secrets/restic-password";
			pruneOpts = [
				"--keep-daily 14"
				"--keep-weekly 4"
				"--keep-monthly 2"
				"--group-by tags"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/twenty-crm";
		};
		services.restic.backups."twenty-crm-files" = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/mnt/bigdisk/twenty-crm-data"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/twenty-crm";
		};
		sops.secrets.twenty-crm-env = {
			format = "dotenv";
			group = user;
			mode = "0440";
			owner = user;
			restartUnits = ["podman-twenty-crm-webserver.service" "podman-twenty-crm-worker.service"];
			sopsFile = ../../secrets/twenty-crm.env;
		};
		users.groups."${group}" = {};
		users.users."${user}" = {
			group = group;
			isSystemUser = true;
		};
		virtualisation.oci-containers.containers.twenty-crm-webserver = {
			environment = {
				DISABLE_DB_MIGRATIONS = "false";
				DISABLE_CRON_JOBS_REGISTRATION = "false";
			};
			environmentFiles = [
				"/var/run/secrets/twenty-crm-env"
			];
			image = "docker.io/twentycrm/twenty:${tag}";
			ports = [ "127.0.0.1:${port}:3000" ];
			volumes = [
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
				"/mnt/bigdisk/twenty-crm-data:/app/packages/twenty-server/.local-storage"
				"/home/eliribble/src/twentycrm/entrypoint.sh:/app/entrypoint.sh"
			];
		};
		virtualisation.oci-containers.containers.twenty-crm-worker = {
			cmd = ["yarn" "worker:prod"];
			environment = {
				DISABLE_DB_MIGRATIONS = "true";
				DISABLE_CRON_JOBS_REGISTRATION = "true";
			};
			environmentFiles = [
				"/var/run/secrets/twenty-crm-env"
			];
			image = "docker.io/twentycrm/twenty:${tag}";
			ports = [ "127.0.0.1:3000:${port}" ];
			volumes = [
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
				"twenty-crm-data:/app/packages/twenty-server/.local-storage"
			];
		};
	};
}
