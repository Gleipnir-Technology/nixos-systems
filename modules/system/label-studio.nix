{ lib, config, nixpkgs, pkgs, ... }:
with lib;
{
	options.myModules.label-studio.enable = mkEnableOption "custom label-studio configuration";

	config = mkIf config.myModules.label-studio.enable {
		services.caddy.virtualHosts."label-studio.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10070
		'';
		services.postgresql = {
			ensureDatabases = [ "label-studio" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "label-studio";
			}];
		};
		services.restic.backups."label-studio-db" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump label-studio"
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
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/label-studio";
		};
		services.restic.backups."label-studio-files" = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/mnt/bigdisk/label-studio"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/label-studio";
		};
		sops.secrets.label-studio-env = {
			format = "dotenv";
			group = "label-studio";
			mode = "0440";
			owner = "label-studio";
			restartUnits = ["podman-label-studio.service"];
			sopsFile = ../../secrets/label-studio.env;
		};
		systemd.tmpfiles.rules = [
			"d /mnt/bigdisk/label-studio 0755 label-studio label-studio"
		];
		virtualisation.oci-containers.containers.label-studio = {
			environmentFiles = [
				"/var/run/secrets/label-studio-env"
			];
			extraOptions = [
				"--userns=keep-id:uid=1001,gid=0"
			];
			image = "docker.io/heartexlabs/label-studio:1.22.0";
			ports = [ "127.0.0.1:10070:8080" ];
			volumes = [
				"/mnt/bigdisk/label-studio:/label-studio/data"
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
			];
		};
		users.groups.label-studio = {};
		users.users.label-studio = {
			uid = 1001;
			group = "label-studio";
			isSystemUser = true;
		};
	};
}
