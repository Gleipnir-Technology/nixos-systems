{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.librechat.enable = mkEnableOption "custom librechat configuration";

	config = mkIf config.myModules.librechat.enable {
		environment.systemPackages = [
			(pkgs.librechat.overrideAttrs (
				final: prev: {
					pname = "librechat";
					version = "0.7.9-rc1";
					src = pkgs.fetchFromGitHub {
						owner = "danny-avila";
						repo = "LibreChat";
						rev = "v${final.version}";
						sha256 = "sha256-IC/KyHfHYeUo8bXY/JU2cMvCwsUsiAyTZGyslpzjwKg=";
					};
					npmDepsHash = "sha256-zVqr/yNwQeytPlmhU+yfeXOUbIpczM1qhRX8MOfM584=";
					npmDeps = pkgs.fetchNpmDeps {
						inherit (final) src;
						name = "${final.pname}-${final.version}-npm-deps";
						hash = final.npmDepsHash;
					};
				}
			))
		];
		services.caddy.virtualHosts."ai.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10050
		'';
		services.mongodb = {
			enable = true;
		};
		sops.secrets.librechat-env = {
			format = "dotenv";
			group = "librechat";
			mode = "0440";
			owner = "librechat";
			restartUnits = ["librechat.service"];
			sopsFile = ../../secrets/librechat.env;
		};
		systemd.services.librechat = {
			after=["network.target" "network-online.target"];
			description="Self-hosted LLM chat frontend";
			documentation=["https://www.librechat.ai/docs"];
			requires=["network-online.target"];
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/librechat-env";
				Type = "simple";
				User = "librechat";
				Group = "librechat";
				ExecStart = "${pkgs.librechat}/bin/librechat-server";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/opt/librechat";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.tmpfiles.rules = [
			"d /opt/librechat 0755 librechat librechat"
		];
		users.groups.librechat = {};
		users.users.librechat = {
			group = "librechat";
			isNormalUser = false;
			isSystemUser = true;
		};

	};
}
