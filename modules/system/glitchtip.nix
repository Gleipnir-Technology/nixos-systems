{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.glitchtip.enable = mkEnableOption "custom glitchtip configuration";

	config = mkIf config.myModules.glitchtip.enable {
		services.caddy.virtualHosts."glitchtip.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10060
		'';
		services.glitchtip = {
			enable = true;
			#environment = [
				#"TMPDIR=/tmp/glitchtip"
			#];
			environmentFiles = [
				"/var/run/secrets/glitchtip-env"
			];
			port = 10060;
			settings.GLITCHTIP_DOMAIN = "https://glitchtip.gleipnir.technology";
			#workingDirectory = "/mnt/bigdisk/glitchtip";
		};
		services.restic.backups."glitchtip-db" = {
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump glitchtip"
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
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/glitchtip";
		};
		services.restic.backups."glitchtip-files" = {
			environmentFile = "/var/run/secrets/glitchtip-env";
			extraBackupArgs = [
				"--tag files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/mnt/bigdisk/glitchtip"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/glitchtip";
			
		};
		sops.secrets.glitchtip-env = {
			format = "dotenv";
			group = "glitchtip";
			mode = "0440";
			owner = "glitchtip";
			restartUnits = ["glitchtip.service"];
			sopsFile = ../../secrets/glitchtip.env;
		};
		systemd.tmpfiles.rules = [
			"d /tmp/glitchtip 0755 glitchtip glitchtip 1h"
			"d /mnt/bigdisk/glitchtip 0755 glitchtip glitchtip"
			"d /mnt/bigdisk/glitchtip/assets 0755 glitchtip glitchtip"
			"d /mnt/bigdisk/glitchtip/dist 0755 glitchtip glitchtip"
			"d /mnt/bigdisk/glitchtip/static 0755 glitchtip glitchtip"
			"d /mnt/bigdisk/glitchtip/uploads 0755 glitchtip glitchtip"
		];
	};
}
