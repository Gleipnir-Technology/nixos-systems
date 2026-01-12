{ customer, dataDirectory, fieldseeker-sync, lib, pkgs, port, subdomain, ... }:
with lib;
let
	backupName = "${customer}-db";
	databaseName = "fss-${customer}";
	databaseUser = "fss-${customer}";
	environmentFile = "/var/run/secrets/fss-${customer}-env";
	fieldseeker-sync-pkg = fieldseeker-sync.packages.x86_64-linux.default;
	fqdn = "${subdomain}.nidus.cloud";
	group = "fss-${customer}";
	user = "fss-${customer}";
in {
	environment.systemPackages = [
		fieldseeker-sync-pkg
		pkgs.ffmpeg
	];
	services.caddy.virtualHosts."${subdomain}.nidus.cloud" = {
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
	sops.secrets."fss-${customer}-env" = {
		format = "dotenv";
		group = "${group}";
		mode = "0440";
		owner = "${user}";
		restartUnits = ["fss-${customer}-webserver.service"];
		sopsFile = ../../secrets/fieldseeker-sync/${customer}.env;
	};
	systemd.services."fss-${customer}-migrate" = {
		after=["network.target" "network-online.target"];
		description="FieldSeeker DB migrate";
		requires=["network-online.target"];
		serviceConfig = {
			Environment="SENTRY_RELEASE=${fieldseeker-sync.rev}";
			EnvironmentFile="${environmentFile}";
			Type = "oneshot";
			User = "${user}";
			Group = "${group}";
			ExecStart = "${fieldseeker-sync-pkg}/bin/migrate";
			TimeoutStopSec = "5s";
			PrivateTmp = true;
			WorkingDirectory = "/tmp";
		};
		wantedBy = ["multi-user.target"];
	};
	systemd.services."fss-${customer}-webserver" = {
		after=["network.target" "network-online.target" "fss-${customer}-migrate.service"];
		description="FieldSeeker sync";
		path = [ pkgs.ffmpeg ];
		requires=["network-online.target"];
		serviceConfig = {
			Environment="SENTRY_RELEASE=${fieldseeker-sync.rev}";
			EnvironmentFile="${environmentFile}";
			Type = "simple";
			User = "${user}";
			Group = "${group}";
			ExecStart = "${fieldseeker-sync-pkg}/bin/webserver";
			TimeoutStopSec = "5s";
			PrivateTmp = true;
			WorkingDirectory = "/tmp";
		};
		wantedBy = ["multi-user.target"];
	};
	users.groups.${group} = {};
	users.users.${user} = {
		group = "${group}";
		isSystemUser = true;
	};
}
