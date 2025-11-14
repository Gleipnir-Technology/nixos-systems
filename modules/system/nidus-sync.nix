{ config, inputs, lib, nidus-sync, pkgs, ... }:
with lib;
let
	backupName = nidusName;
	databaseName = nidusName;
	databaseUser = nidusName;
	dataDirectory = /mnt/bigdisk/nidus-sync;
	domainName = "sync.nidus.cloud";
	group = nidusName;
	nidusName = "nidus-sync";
	nidus-sync-pkg = inputs.nidus-sync.packages.x86_64-linux.default;
	port = 10000;
	secretsName = "${nidusName}-env";
	user = nidusName;

	environmentFile = "/var/run/secrets/${nidusName}-env";
in {
	options.myModules.nidus-sync.enable = mkEnableOption "custom nidus-sync configuration";

	config = mkIf config.myModules.nidus-sync.enable {
		environment.systemPackages = with pkgs; [
			ffmpeg
			nidus-sync-pkg
		];
		services.caddy.virtualHosts."${domainName}" = {
			extraConfig = ''
				reverse_proxy http://127.0.0.1:${toString port}
			'';
		};
		services.postgresql = {
			enable = true;
			ensureDatabases = [databaseName];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = databaseUser;
			}];
			extensions = ps: with ps; [ h3-pg postgis ];
		};
		services.restic.backups."${backupName}-db" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump ${databaseName}"
			];
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag database"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			pruneOpts = [
				"--keep-daily 14"
				"--keep-weekly 4"
				"--keep-monthly 2"
				"--group-by tags"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-deltamvcd/database";
		};
		services.restic.backups."${backupName}-files" = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag user-files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				(builtins.toString dataDirectory)
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-deltamvcd/files";
			
		};
		sops.secrets."${secretsName}" = {
			format = "dotenv";
			group = "${group}";
			mode = "0440";
			owner = "${user}";
			restartUnits = ["${nidusName}-webserver.service"];
			sopsFile = ../../secrets/${nidusName}.env;
		};
		systemd.services."${nidusName}-webserver" = {
			after=["network.target" "network-online.target"];
			description="Nidus Sync Webserver";
			path = [ pkgs.ffmpeg ];
			requires=["network-online.target"];
			serviceConfig = {
				Group = "${group}";
				Environment="SENTRY_RELEASE=${inputs.nidus-sync.rev}";
				EnvironmentFile="${environmentFile}";
				ExecStart = "${nidus-sync-pkg}/bin/nidus-sync";
				PrivateTmp = true;
				TimeoutStopSec = "5s";
				Type = "simple";
				User = "${user}";
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		users.groups.${group} = {};
		users.users.${user} = {
			group = "${group}";
			isSystemUser = true;
		};
	};
}
