{ config, inputs, lib, pkgs, ... }:
with lib;
let
	cfg = config.myModules.fieldseeker-sync;
	fieldseeker-sync-pkg = inputs.fieldseeker-sync.packages.x86_64-linux.default;
	mkMergeTopLevel = names: attrs:
		lib.getAttrs names (
			lib.mapAttrs (_k: v: lib.mkMerge v) (lib.foldAttrs (n: a: [ n ] ++ a) [ ] attrs)
		);
in {
	options.myModules.fieldseeker-sync.deployments = mkOption {
		type = types.listOf (types.submodule {
			options = {
				customer = mkOption {
					type = types.str;
					description = "Name of the customer";
				};

				dataDirectory = mkOption {
					type = types.path;
					description = "Directory for the data files";
				};

				port = mkOption {
					type = types.int;
					description = "Port for the service";
				};

				secretsPath = mkOption {
					type = types.path;
					description = "Path to the secrets file";
				};

				subdomain = mkOption {
					type = types.str;
					description = "Subdomain for the customer";
				};

			};
		});
		default = [];
		description = "List of fieldseeker deployments";
	};
	config = mkMergeTopLevel ["environment" "services" "sops" "systemd" "users"] (
		map ( deployment:
			let
				backupName = "${deployment.customer}-db";
				databaseName = "fss-${deployment.customer}";
				databaseUser = "fss-${deployment.customer}";
				environmentFile = "/var/run/secrets/fss-${deployment.customer}-env";
				fqdn = "${deployment.subdomain}.nidus.cloud";
				group = "fss-${deployment.customer}";
				user = "fss-${deployment.customer}";
			in {
				environment.systemPackages = [
					fieldseeker-sync-pkg
					pkgs.ffmpeg
				];
				services.caddy.virtualHosts."${deployment.subdomain}.nidus.cloud" = {
					extraConfig = ''
						reverse_proxy http://127.0.0.1:${toString deployment.port}
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
						(builtins.toString deployment.dataDirectory)
					];
					repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-deltamvcd/files";
					
				};
				sops.secrets."fss-${deployment.customer}-env" = {
					format = "dotenv";
					group = "${group}";
					mode = "0440";
					owner = "${user}";
					restartUnits = ["fss-${deployment.customer}-webserver.service"];
					sopsFile = ../../secrets/fieldseeker-sync/${deployment.customer}.env;
				};
				systemd.services."fss-${deployment.customer}-export" = {
					after=["network.target" "network-online.target" "fss-${deployment.customer}-migrate.service"];
					description="FieldSeeker sync periodic sync tool";
					requires=["network-online.target"];
					restartIfChanged = false;
					stopIfChanged = false;
					serviceConfig = {
						EnvironmentFile="${environmentFile}";
						ExecStart = "${fieldseeker-sync-pkg}/bin/full-export";
						Group = "${group}";
						PrivateTmp = true;
						TimeoutStopSec = "5s";
						Type = "simple";
						User = "${user}";
						WorkingDirectory = "/tmp";
					};
					startAt = "*:0/15";
					wantedBy = ["multi-user.target"];
				};
				systemd.services."fss-${deployment.customer}-migrate" = {
					after=["network.target" "network-online.target"];
					description="FieldSeeker DB migrate";
					requires=["network-online.target"];
					serviceConfig = {
						Environment="SENTRY_RELEASE=${inputs.fieldseeker-sync.rev}";
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
				systemd.services."fss-${deployment.customer}-webserver" = {
					after=["network.target" "network-online.target" "fss-${deployment.customer}-migrate.service"];
					description="FieldSeeker sync";
					path = [ pkgs.ffmpeg ];
					requires=["network-online.target"];
					serviceConfig = {
						Environment="SENTRY_RELEASE=${inputs.fieldseeker-sync.rev}";
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
		) cfg.deployments
	);
}
