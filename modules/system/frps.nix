{ config, configFiles, inputs, lib, pkgs, ... }:
with lib;
let
	cfg = config.myModules.frps;
	group = "frps";
	user = "frps";
in {
	options.myModules.frps = {
		domains = mkOption {
			type = types.listOf types.str;
			description = "All the domains to handle";
		};
		enable = mkEnableOption "custom frps configuration";
	};
	config = mkIf config.myModules.frps.enable {
		environment = {
			etc."frps.toml".source = "${configFiles}/frps/frps.toml";
			systemPackages = [
				pkgs.frp
			];

		};
		services.caddy.virtualHosts = mkMerge (
			map (domain: {
				"${domain}" = {
					extraConfig = ''
						reverse_proxy [::1]:8000
					'';
				};
			}) cfg.domains
		);
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
			environment = {
				FRPS_BIND_PORT="7000";
				FRPS_VHOST_HTTP_PORT="8000";
			};
			requires=["network-online.target"];
			restartIfChanged = true;
			stopIfChanged = true;
			serviceConfig = {
				EnvironmentFile = "/var/run/secrets/frps-env";
				Type = "simple";
				User = "${user}";
				Group = "${group}";
				ExecStart = "${pkgs.frp}/bin/frps -c /etc/frps.toml";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/tmp";
			};
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
