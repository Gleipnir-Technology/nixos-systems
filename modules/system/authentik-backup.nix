{ config, lib, myutils, pkgs, ... }:

let
	backupScript = pkgs.stdenv.mkDerivation {
		name = "backup-authentik-db-script";
		src = ../../scripts/backup-authentik-db.sh; # Path to the script file
		phases = "installPhase";
		installPhase = ''
			mkdir -p $out/bin
			cp $src $out/bin/backup-authentik-db.sh
			chmod +x $out/bin/backup-authentik-db.sh
		'';
	};
in
{
	config = lib.mkIf config.myModules.authentik.enable {
		sops.secrets.authentik-backup-pgpass = {
			mode = "0400";
		};
		systemd.services.backup-authentik-db = {
			description = "Backup authentik database";
			after = [ "network-online.target" ];
			wants = [ "network-online.target" ];
			path = [ pkgs.bash pkgs.postgresql ];
			requires = [ "podman-authentik-worker.service" ];	# Ensure authentik is running first
			script = "${backupScript}/bin/backup-authentik-db.sh";
			serviceConfig = {
				# Needs root so it can stop other services
				User = "root";
				Group = "root";
				Environment = "PGPASSFILE=${config.sops.secrets.authentik-backup-pgpass.path}";
				EnvironmentFile = "/var/run/secrets/authentik-env";
				Type = "oneshot";
				Restart = "on-failure";
			};
			wantedBy = [ "timers.target" ];
		};

		systemd.tmpfiles.rules = [
			"d /var/backups/authentik-db 0755 root root"
		];
		systemd.timers.backup-authentik-db = {
			description = "Daily backup of authentik database";
			wantedBy = [ "timers.target" ];
			timerConfig = {
				OnCalendar = "*-*-* 03:00:00"; # Run daily at 3:00 AM (adjust as needed)
				Persistent = true; # If the system was off when it should have run, run it on startup
			};
		};

		environment.systemPackages = [ pkgs.postgresql ];
	};
}
