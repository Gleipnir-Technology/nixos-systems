{ pkgs, lib, config, ... }:
with lib;
let
	src = pkgs.callPackage (pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "fieldseeker-sync";
		rev    = "2aa2d37e1ccd9471d332d36042fb0b1edd89d08f";
		sha256 = "sha256-Sa69TONC+EJW9/SmbrimJptnqmxQc1uh2NfY9UuD7e0=";
  	}) { };
in {
	options.myModules.fieldseeker-sync.enable = mkEnableOption "custom fieldseeker-sync configuration";

	config = mkIf config.myModules.fieldseeker-sync.enable {
		environment.systemPackages = [
			src
		];
		services.postgresql.enable = true;
		sops.secrets.fieldseeker-sync-env = {
			format = "dotenv";
			group = "fieldseeker-sync";
			mode = "0440";
			owner = "fieldseeker-sync";
			restartUnits = ["fieldseeker-sync.service"];
			sopsFile = ../../secrets/fieldseeker-sync.env;
		};
		systemd.services.fieldseeker-sync = {
			after=["network.target" "network-online.target"];
			description="FieldSeeker sync";
			requires=["network-online.target"];
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/fieldseeker-sync-env";
				Type = "simple";
				User = "fieldseeker-sync";
				Group = "fieldseeker-sync";
				ExecStart = "${src}/bin/full-export";
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
