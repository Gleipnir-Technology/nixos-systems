{ pkgs, lib, config, ... }:
with lib;
let
	src = pkgs.callPackage (pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "fieldseeker-sync";
		rev    = rev;
		sha256 = "sha256-Y8B/HcBzne5sn3/W3p444VT5nx5ltXqoPMX9PPnJ5M8=";
  	}) { };
	rev = "0.0.25";
in {
	options.myModules.fieldseeker-sync.enable = mkEnableOption "custom fieldseeker-sync configuration";

	config = mkIf config.myModules.fieldseeker-sync.enable {
		environment.systemPackages = [
			pkgs.ffmpeg
			src
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
		sops.secrets.fieldseeker-sync-env = {
			format = "dotenv";
			group = "fieldseeker-sync";
			mode = "0440";
			owner = "fieldseeker-sync";
			restartUnits = ["fieldseeker-sync.service"];
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
		systemd.services.fieldseeker-sync-audio-post-processor = {
			after=["network.target" "network-online.target" "fieldseeker-sync-migrate.service"];
			description="FieldSeeker sync audio post processor";
			requires=["network-online.target"];
			restartIfChanged = false;
			stopIfChanged = false;
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/audio-post-processor";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
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
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/audio-post-processor";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
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
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/full-export";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
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
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/full-export";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.services.fieldseeker-sync-migrate = {
			after=["network.target" "network-online.target"];
			description="FieldSeeker DB migrate";
			requires=["network-online.target"];
			serviceConfig = {
				Environment="SENTRY_RELEASE=${rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/migrate";
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
				Environment="SENTRY_RELEASE=${rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-gleipnir-env";
				Type = "oneshot";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/migrate";
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
				Environment="SENTRY_RELEASE=${rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/webserver";
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
				Environment="SENTRY_RELEASE=${rev}";
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-gleipnir-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/webserver";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.timers.fieldseeker-sync-audio-post-processor = {
			wantedBy = ["timers.target"];
			timerConfig = {
				OnBootSec = "15m";
				OnUnitActiveSec = "15m";
				Unit = "fieldseeker-sync-audio-post-processor.service";
			};
		};
		systemd.timers.fieldseeker-sync-gleipnir-audio-post-processor = {
			wantedBy = ["timers.target"];
			timerConfig = {
				OnBootSec = "15m";
				OnUnitActiveSec = "15m";
				Unit = "fieldseeker-sync-gleipnir-audio-post-processor.service";
			};
		};
		systemd.timers.fieldseeker-sync-export = {
			wantedBy = ["timers.target"];
			timerConfig = {
				OnBootSec = "15m";
				OnUnitActiveSec = "15m";
				Unit = "fieldseeker-sync-export.service";
			};
		};
		systemd.timers.fieldseeker-sync-gleipnir-export = {
			wantedBy = ["timers.target"];
			timerConfig = {
				OnBootSec = "15m";
				OnUnitActiveSec = "15m";
				Unit = "fieldseeker-sync-gleipnir-export.service";
			};
		};
		users.groups.fieldseeker-sync = {};
		users.users.fieldseeker-sync = {
			group = "fieldseeker-sync";
			isSystemUser = true;
		};
	};
}
