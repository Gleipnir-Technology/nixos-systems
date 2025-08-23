{ pkgs, lib, config, ... }:
with lib;
let
	src = pkgs.callPackage (pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "fieldseeker-sync";
		rev    = "0.0.2";
		sha256 = "sha256-gLtHQn/5AK5SOT4vs3I/CrO+59dZFwEjuUbc4Aknr8k=";
  	}) { };
in {
	options.myModules.fieldseeker-sync.enable = mkEnableOption "custom fieldseeker-sync configuration";

	config = mkIf config.myModules.fieldseeker-sync.enable {
		environment.systemPackages = [
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
		systemd.services.fieldseeker-sync-export = {
			after=["network.target" "network-online.target"];
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
			after=["network.target" "network-online.target"];
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
		systemd.services.fieldseeker-sync-webserver = {
			after=["network.target" "network-online.target"];
			description="FieldSeeker sync";
			requires=["network-online.target"];
			serviceConfig = {
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
			after=["network.target" "network-online.target"];
			description="FieldSeeker sync";
			requires=["network-online.target"];
			serviceConfig = {
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
