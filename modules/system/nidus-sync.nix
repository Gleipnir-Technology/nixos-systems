{ config, inputs, lib, nidus-sync, pkgs, ... }:
with lib;
let
	backupName = nidusName;
	cfg = config.myModules.nidus-sync;
	databaseName = nidusName;
	databaseUser = nidusName;
	dataDirectory = /mnt/bigdisk/nidus-sync;
	dataDirectoryString = "/mnt/bigdisk/nidus-sync";
	group = nidusName;
	nidusName = "nidus-sync";
	nidusNameSocket = "${nidusName}";
	nidusNameWebserver = "${nidusName}-webserver";
	nidus-sync-pkg = inputs.nidus-sync.packages.x86_64-linux.default;
	port = 10000;
	secretsName = "${nidusName}-env";
	user = nidusName;

	environmentFile = "/var/run/secrets/${nidusName}-env";
in {
	options.myModules.nidus-sync = {
		domainNameReport = mkOption {
			example = "report.mosquitoes.online";
			type = types.str;
		};
		domainNameSync = mkOption {
			example = "sync.nidus.cloud";
			type = types.str;
		};
		enable = mkEnableOption "custom nidus-sync configuration";
		environment = mkOption {
			example = "prod";
			type = types.str;
		};
	};

	config = mkIf config.myModules.nidus-sync.enable {
		environment.systemPackages = with pkgs; [
			ffmpeg
			nidus-sync-pkg
		];
		services.caddy.virtualHosts."${cfg.domainNameReport}" = {
			extraConfig = ''
				reverse_proxy http://127.0.0.1:${toString port}
			'';
		};
		services.caddy.virtualHosts."${cfg.domainNameSync}" = {
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
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-nidus-sync/database";
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
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-nidus-sync/files";
			
		};
		sops.secrets."${secretsName}" = {
			format = "dotenv";
			group = "${group}";
			mode = "0440";
			owner = "${user}";
			restartUnits = ["${nidusNameWebserver}.service"];
			sopsFile = ../../secrets/${cfg.environment}/${nidusName}.env;
		};
		systemd.services."${nidusNameWebserver}" = {
			after=["${nidusNameSocket}.socket" "network.target"];
			description="Nidus Sync Webserver";
			path = with pkgs; [
				ffmpeg
				google-chrome
			];
			requires=["${nidusNameSocket}.socket"];
			serviceConfig = {
				Group = "${group}";
				Environment=[
					"SENTRY_RELEASE=${inputs.nidus-sync.rev}"
					"HOME=/var/lib/nidus-sync"
				];
				EnvironmentFile="${environmentFile}";
				ExecStart = "${nidus-sync-pkg}/bin/nidus-sync";
				KillMode = "mixed"; # SIGTERM to main process, SIGKILL to process group after timeout
				KillSignal = "SIGTERM";
				PrivateTmp = true;
				Restart = "on-failure";
				StateDirectory = "nidus-sync"; # Creates /var/lib/nidus-sync
				TimeoutStopSec = 30;
				Type = "simple";
				User = "${user}";
				WorkingDirectory = "/var/lib/nidus-sync";
			};
		};
		systemd.sockets."${nidusNameSocket}" = {
			listenStreams = [ "${toString port}" ];
			socketConfig = {
				BindIPv6Only = "both";
				Service = "${nidusNameWebserver}.service";
			};
			wantedBy = [ "multi-user.target" ];
		};
		systemd.tmpfiles.rules = [
			"d ${dataDirectoryString} 0755 ${nidusName} ${nidusName}"
			"d ${dataDirectoryString} 0755 ${nidusName} ${nidusName}"
		];
		users.groups.${group} = {};
		users.users.${user} = {
			group = "${group}";
			isSystemUser = true;
		};
	};
}
