{ config, inputs, lib, pkgs, ... }:
with lib;
let
	fieldseeker-sync-pkg = inputs.fieldseeker-sync.packages.x86_64-linux.default;
in {
	options.myModules.fieldseeker-sync.enable = mkEnableOption "custom fieldseeker-sync configuration";

	config = mkIf config.myModules.fieldseeker-sync.enable {
		environment.systemPackages = [
			fieldseeker-sync-pkg
			pkgs.ffmpeg
		];
		services.caddy.virtualHosts."deltamvcd.nidus.cloud".extraConfig = ''
			reverse_proxy http://127.0.0.1:3000
		'';
		services.caddy.virtualHosts."gleipnir.nidus.cloud".extraConfig = ''
			reverse_proxy http://127.0.0.1:3001
		'';
		services.postgresql = {
			enable = true;
			ensureDatabases = [ "fieldseeker-sync" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "fieldseeker-sync";
			}];
		};
		services.restic.backups.deltamvcd-db = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump fieldseeker-sync"
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
		services.restic.backups.deltamvcd-files = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag user-files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/opt/fieldseeker-sync/deltamvcd"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-deltamvcd/files";
			
		};
		sops.secrets.fieldseeker-sync-env = {
			format = "dotenv";
			group = "fieldseeker-sync";
			mode = "0440";
			owner = "fieldseeker-sync";
			restartUnits = ["fieldseeker-sync-webserver.service"];
			sopsFile = ../../secrets/fieldseeker-sync.env;
		};
		sops.secrets.fieldseeker-sync-gleipnir-env = {
			format = "dotenv";
			group = "fieldseeker-sync";
			mode = "0440";
			owner = "fieldseeker-sync";
			restartUnits = ["fieldseeker-sync-gleipnir.service"];
			sopsFile = ../../secrets/fieldseeker-sync-gleipnir.env;
		};
		sops.secrets.restic-env = {
			format = "yaml";
			key = "backblaze";
			group = "root";
			mode = "0440";
			owner = "root";
			#restartUnits = ["fieldseeker-sync.service"];
			sopsFile = ../../secrets/restic.yaml;
		};
		sops.secrets.restic-password = {
			format = "yaml";
			key = "password";
			group = "root";
			mode = "0440";
			owner = "root";
			#restartUnits = ["fieldseeker-sync.service"];
			sopsFile = ../../secrets/restic.yaml;
		};
		systemd.services.fieldseeker-sync-audio-post-processor = {
			after=["network.target" "network-online.target" "fieldseeker-sync-migrate.service"];
			description="FieldSeeker sync audio post processor";
			requires=["network-online.target"];
			restartIfChanged = false;
			stopIfChanged = false;
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${fieldseeker-sync-pkg}/bin/audio-post-processor";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			startAt = "*:0/15";
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-gleipnir-audio-post-processor = {
			after=["network.target" "network-online.target" "fieldseeker-sync-gleipnir-migrate.service"];
			description="FieldSeeker sync audio post processor";
			requires=["network-online.target"];
			restartIfChanged = false;
			stopIfChanged = false;
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-gleipnir-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${fieldseeker-sync-pkg}/bin/audio-post-processor";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			startAt = "*:0/15";
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-export = {
			after=["network.target" "network-online.target" "fieldseeker-sync-migrate.service"];
			description="FieldSeeker sync periodic sync tool";
			requires=["network-online.target"];
			restartIfChanged = false;
			stopIfChanged = false;
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				ExecStart = "${fieldseeker-sync-pkg}/bin/full-export";
				Group = "fieldseeker-sync";
				PrivateTmp = true;
				TimeoutStopSec = "5s";
				Type = "simple";
				User = "fieldseeker-sync";
				WorkingDirectory = "/tmp";
			};
			startAt = "*:0/15";
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-gleipnir-export = {
			after=["network.target" "network-online.target" "fieldseeker-sync-gleipnir-migrate.service"];
			description="FieldSeeker sync periodic sync tool";
			requires=["network-online.target"];
			restartIfChanged = false;
			stopIfChanged = false;
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-gleipnir-env";
				ExecStart = "${fieldseeker-sync-pkg}/bin/full-export";
				Group = "fieldseeker-sync";
				PrivateTmp = true;
				TimeoutStopSec = "5s";
				Type = "simple";
				User = "fieldseeker-sync";
				WorkingDirectory = "/tmp";
			};
			startAt = "*:0/15";
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-migrate = {
			after=["network.target" "network-online.target"];
			description="FieldSeeker DB migrate";
			requires=["network-online.target"];
			serviceConfig = {
				Environment="SENTRY_RELEASE=${inputs.fieldseeker-sync.rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${fieldseeker-sync-pkg}/bin/migrate";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-gleipnir-migrate = {
			after=["network.target" "network-online.target"];
			description="FieldSeeker Gleipnir DB migrate";
			requires=["network-online.target"];
			serviceConfig = {
				Environment="SENTRY_RELEASE=${inputs.fieldseeker-sync.rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-gleipnir-env";
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${fieldseeker-sync-pkg}/bin/migrate";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-webserver = {
			after=["network.target" "network-online.target" "fieldseeker-sync-migrate.service"];
			description="FieldSeeker sync";
			requires=["network-online.target"];
			serviceConfig = {
				Environment="SENTRY_RELEASE=${inputs.fieldseeker-sync.rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${fieldseeker-sync-pkg}/bin/webserver";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-gleipnir-webserver = {
			after=["network.target" "network-online.target" "fieldseeker-sync-gleipnir-migrate.service"];
			description="FieldSeeker sync";
			requires=["network-online.target"];
			serviceConfig = {
				Environment="SENTRY_RELEASE=${inputs.fieldseeker-sync.rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-gleipnir-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${fieldseeker-sync-pkg}/bin/webserver";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		users.groups.fieldseeker-sync = {};
		users.users.fieldseeker-sync = {
			group = "fieldseeker-sync";
			isSystemUser = true;
		};
	};
}
