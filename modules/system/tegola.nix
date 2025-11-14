{ config, configFiles, lib, pkgs, ... }:
with lib;

let
	databaseName = "tegola";
	databaseUser = "tegola";
	group = "tegola";
	user = "tegola";
in {
	options.myModules.tegola.enable = mkEnableOption "custom tegola configuration";

	config = mkIf config.myModules.tegola.enable {
		environment = {
			etc."tegola.toml" = {
				group = group;
				source = "${configFiles}/tegola.toml";
				user = user;
			};
			systemPackages = with pkgs; [
				tegola
			];
		};
		networking.firewall.allowedTCPPorts = [ 9090 ];
		services.postgresql = {
			enable = true;
			ensureDatabases = [databaseName];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = databaseUser;
			}];
			extensions = ps: with ps; [ h3-pg postgis ];
		};
		systemd.services."tegola" = {
			after=["network.target" "network-online.target"];
			description="Tegola Vector Tile";
			path = [ pkgs.tegola ];
			requires=["network-online.target"];
			serviceConfig = {
				Group = group;
				ExecStart = "${pkgs.tegola}/bin/tegola serve --config /etc/tegola.toml";
				PrivateTmp = true;
				TimeoutStopSec = "5s";
				Type = "simple";
				User = user;
				WorkingDirectory = "/tmp";
			};
			wantedBy = ["multi-user.target"];
		};
		users = {
			groups."${group}" = {};
			users."${user}" = {
				group = group;
				isSystemUser = true;
			};
		};
	};
}
