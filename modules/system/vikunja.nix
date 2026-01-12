{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.vikunja.enable = mkEnableOption "custom vikunja configuration";

	config = mkIf config.myModules.vikunja.enable {
		services.caddy.virtualHosts."todo.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10010
		'';
		services.postgresql = {
			ensureDatabases = [ "vikunja" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "vikunja";
			}];
		};
		services.restic.backups."vikunja-db" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump vikunja"
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
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/vikunja";
		};
		services.restic.backups."vikunja-files" = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/var/lib/vikunja"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/vikunja";
		};
		services.vikunja = {
			enable = true;
			frontendHostname = "todo.gleipnir.technology";
			frontendScheme = "https";
			settings = {
				service.interface = lib.mkForce "127.0.0.1:3456";
			};
		};
		sops.secrets.vikunja = {
			format = "yaml";
			group = "vikunja";
			key = "";
			owner = "vikunja";
			path = "/etc/vikunja/config.yaml";
			restartUnits = [ "vikunja.service" ];
			sopsFile = ../../secrets/vikunja.yaml;
		};
		users.groups.vikunja = {};
		users.users.vikunja = {
			group = "vikunja";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
