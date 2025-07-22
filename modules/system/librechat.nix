{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.librechat.enable = mkEnableOption "custom librechat configuration";

	config = mkIf config.myModules.librechat.enable {
		environment.systemPackages = [
			pkgs.librechat
			pkgs.meilisearch
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
		sops.secrets.meilisearch-env = {
			format = "dotenv";
			group = "meilisearch";
			mode = "0440";
			owner = "meilisearch";
			restartUnits = ["meilisearch.service"];
			sopsFile = ../../secrets/meilisearch.env;
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
		systemd.services.meilisearch = {
			after=["network.target" "network-online.target"];
			description="Self-hosted LLM chat search";
			documentation=["https://www.meilisearch.com/docs/learn/self_hosted/configure_meilisearch_at_launch"];
			requires=["network-online.target"];
			serviceConfig = {
				EnvironmentFile="/var/run/secrets/meilisearch-env";
				Type = "simple";
				User = "meilisearch";
				Group = "meilisearch";
				ExecStart = "${pkgs.meilisearch}/bin/meilisearch";
				TimeoutStopSec = "5s";
				PrivateTmp = true;
				WorkingDirectory = "/opt/meilisearch";
			};
			wantedBy = ["multi-user.target"];
		};
		systemd.tmpfiles.rules = [
			"d /opt/librechat 0755 librechat librechat"
			"d /opt/meilisearch 0755 meilisearch meilisearch"
		];
		users.groups.librechat = {};
		users.groups.meilisearch = {};
		users.users.librechat = {
			group = "librechat";
			isSystemUser = true;
		};
		users.users.meilisearch = {
			group = "meilisearch";
			isSystemUser = true;
		};

	};
}
