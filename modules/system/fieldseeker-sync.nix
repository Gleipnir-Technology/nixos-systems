{ pkgs, lib, config, ... }:
with lib;
let
	src = pkgs.callPackage (pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "fieldseeker-sync";
		rev    = "ecc408d09e7769dc43cd6a01c09c8d00255802bf";
		sha256 = "sha256-hPdtf78PlkMCXZC3fG7Q7ZVM8moYlwbVnkElR5yx6yA=";
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
		systemd.timers.fieldseeker-sync-export = {
			wantedBy = ["timers.target"];
			timerConfig = {
				OnBootSec = "15m";
				OnUnitActiveSec = "15m";
				Unit = "fieldseeker-sync-export.service";
			};
		};
		users.groups.fieldseeker-sync = {};
		users.users.fieldseeker-sync = {
			group = "fieldseeker-sync";
			isSystemUser = true;
		};
	};
}
