{ config, configFiles, inputs, lib, pkgs, ... }:
with lib;
let
	group = "frps";
	user = "frps";
in {
	options.myModules.frps.enable = mkEnableOption "custom frps configuration";
	config = mkIf config.myModules.frps.enable {
		environment = {
			etc."frps.toml".source = "${configFiles}/frps/frps.toml";
			systemPackages = [
				pkgs.frp
			];

		};
		sops.secrets.frps-env = {
			format = "dotenv";
			group = "${group}";
			mode = "0440";
			owner = "${user}";
			restartUnits = [];
			sopsFile = ../../secrets/frps.env;
		};
		systemd.services.frps = {
			after=["network.target" "network-online.target"];
			description="FRP server process";
			requires=["network-online.target"];
			restartIfChanged = true;
			stopIfChanged = true;
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/frps-env";
				Type = "simple";
				User = "${user}";
				Group = "${group}";
				ExecStart = "${pkgs.frp}/bin/frps -c /etc/frps.toml";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			startAt = "*:0/15";
			wantedBy = ["multi-user.target"];
		};
		users.groups.${group} = {};
		users.users.${user} = {
			group = "${group}";
			isNormalUser = false;
			isSystemUser = true;
		};
	};
}
