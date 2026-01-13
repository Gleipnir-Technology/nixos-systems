{ config, lib, pkgs, ... }:
with lib;
{
	options.myModules.authentik.enable = mkEnableOption "custom authentik configuration";

	config = mkIf config.myModules.authentik.enable {
		environment.systemPackages = [
			pkgs.authentik
		];
		services.authentik = {
			enable = true;
			environmentFile = "/run/secrets/authentik-env";
			settings = {
				database = {
					host = "127.0.0.1";
					name = "authentik";
				};
				email = {
					host = "smtp.forwardemail.net";
					port = 2465;
					use_tls = false;
					use_ssl = true;
					from = "auth@corp.gleipnir.technology";
				};
				listen = {
					debug = "127.0.0.1:9900";
					debug_py = "127.0.0.1:9901";
					http = "127.0.0.1:10030";
					https = "127.0.0.1:10031";
					ldap = "127.0.0.1:3389";
					ldaps = "127.0.0.1:6636";
					radius = "127.0.0.1:1812";
					metrics = "127.0.0.1:9300";
				};
			};
		};
		services.caddy.virtualHosts."auth.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10030
		'';
		services.postgresql = {
			ensureDatabases = [ "authentik" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "authentik";
			}];
		};
		services.restic.backups."authentik-db" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump authentik"
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
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/authentik";
		};
		services.restic.backups."authentik-files" = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/opt/authentik/certs"
				"/opt/authentik/media"
				"/opt/authentik/templates"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/authentik";
		};
		sops.secrets.authentik-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "authentik";
			mode = "0440";
			owner = "authentik";
			restartUnits = ["authentik" "authentik-migrate" "authentik-worker"];
			sopsFile = ../../secrets/authentik.env;
		};
		systemd.tmpfiles.rules = [
			"d /opt/authentik/certs 0755 authentik authentik"
			"d /opt/authentik/media 0755 authentik authentik"
			"d /opt/authentik/templates 0755 authentik authentik"
		];
		users.groups.authentik = {};
		users.users.authentik = {
			group = "authentik";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
