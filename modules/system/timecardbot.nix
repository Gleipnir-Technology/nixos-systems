{ config, lib, pkgs, timecard-bot, ... }:
with lib;
let
	timecard-bot-pkg = timecard-bot.packages.x86_64-linux.default;
in
{
	options.myModules.timecardbot.enable = mkEnableOption "custom timecardbot configuration";

	config = mkIf config.myModules.timecardbot.enable {
		environment.systemPackages = with pkgs; [
			timecard-bot-pkg
		];
		sops.secrets.timecarder-env = {
			format = "dotenv";
			group = "timecarder";
			mode = "0440";
			owner = "timecarder";
			restartUnits = ["timecarder.service"];
			sopsFile = ../../secrets/timecarder.env;
		};
		systemd.services.timecarder = {
			after=["network.target" "network-online.target"];
			description="Timecarder Matrix bot";
			requires=["network-online.target"];
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/timecarder-env";
				Type = "simple";
				User = "timecarder";
				Group = "timecarder";
				ExecStart = "${timecard-bot-pkg}/bin/timecardbot";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		users.groups.timecarder = {};
		users.users.timecarder = {
			group = "timecarder";
			isSystemUser = true;
		};
	};
}
