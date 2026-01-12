{ lib, config, nixpkgs, pkgs, ... }:
with lib;
let
	librechat = (pkgs.callPackage (./librechat/package.nix  ) { });
in
{
	options.myModules.librechat.enable = mkEnableOption "custom librechat configuration";

	config = mkIf config.myModules.librechat.enable {
		environment.etc."librechat.yaml" = {
			source = ../../etc/librechat.yaml;
			mode = "0440";
			user = "librechat";
			group = "librechat";
		};
		environment.systemPackages = [
			librechat
			pkgs.meilisearch
		];
		services.caddy.virtualHosts."ai.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10050
		'';
		services.mongodb = {
			enable = true;
		};
		services.postgresql = {
			ensureDatabases = [ "rag_api" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "rag_api";
			}];
			#extensions = ps: with ps; [ pgvecto-rs ];
			extensions = ps: with ps; [ pgvector ];
			settings = {
				shared_preload_libraries = [ "vector.so" ];
				search_path = "\"$user\", public, vector";
			};
		};
		services.restic.backups."mongodb" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u mongodb"
				"${pkgs.mongodb}/bin/mongodump --archive=/mnt/bigdisk/temp/mongodb"
			];
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag database"
			];
			passwordFile = "/var/run/secrets/restic-password";
			pruneOpts = [
				"--keep-daily 14"
				"--keep-weekly 4"
				"--keep-monthly 2"
				"--group-by tags"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/mongodb";
		};
		services.restic.backups."rag_api-db" = {
			# We can use this due to overridding restic with unstable
			command = [
				"${lib.getExe pkgs.sudo}"
				"-u postgres"
				"${pkgs.postgresql}/bin/pg_dump rag_api"
			];
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag database"
			];
			passwordFile = "/var/run/secrets/restic-password";
			pruneOpts = [
				"--keep-daily 14"
				"--keep-weekly 4"
				"--keep-monthly 2"
				"--group-by tags"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/rag_api";
		};
		services.restic.backups."librechat-files" = {
			environmentFile = "/var/run/secrets/restic-env";
			extraBackupArgs = [
				"--tag files"
			];
			initialize = true;
			passwordFile = "/var/run/secrets/restic-password";
			paths = [
				"/opt/librechat"
			];
			repository = "s3:s3.us-west-004.backblazeb2.com/gleipnir-backup-corp/librechat";
			
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
		sops.secrets."rag-api-credentials.json" = with config.virtualisation.oci-containers; {
			format = "json";
			group = "rag-api";
			mode = "0440";
			owner = "rag-api";
			key = "";
			restartUnits = ["${backend}-rag-api"];
			sopsFile = ../../secrets/rag-api-credentials.json;
		};
		sops.secrets.rag-api-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "rag-api";
			mode = "0440";
			owner = "rag-api";
			restartUnits = ["${backend}-rag-api"];
			sopsFile = ../../secrets/rag-api.env;
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
				ExecStart = "${librechat}/bin/librechat-server";
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
		systemd.services.postgresql.serviceConfig.ExecStartPost =
			let sqlFile = pkgs.writeText "librechat-pgvectors-setup.sql" ''
				CREATE EXTENSION IF NOT EXISTS vector;

				ALTER SCHEMA public OWNER TO rag_api;
				ALTER SCHEMA vector OWNER TO rag_api;

				ALTER EXTENSION vector UPDATE;
			'';
			in [''
				${lib.getExe' config.services.postgresql.package "psql"} -d "rag_api" -f "${sqlFile}"
			''];
		systemd.tmpfiles.rules = [
			"d /opt/librechat 0755 librechat librechat"
			"d /opt/meilisearch 0755 meilisearch meilisearch"
			"d /opt/rag-api 0755 rag-api rag-api"
		];
		users.groups.librechat = {};
		users.groups.meilisearch = {};
		users.groups.rag-api = {};
		users.users.librechat = {
			group = "librechat";
			isSystemUser = true;
		};
		users.users.meilisearch = {
			group = "meilisearch";
			isSystemUser = true;
		};
		users.users.rag-api = {
			group = "rag-api";
			isSystemUser = true;
		};
		virtualisation.oci-containers.containers.rag-api = {
			environmentFiles = [
				"/var/run/secrets/rag-api-env"
			];
			image = "localhost/rag_api:latest";
			ports = [ "127.0.0.1:10051:8000" ];
			volumes = [
				"/opt/rag-api:/app/uploads"
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
				"/var/run/secrets/rag-api-credentials.json:/var/run/secrets/rag-api-credentials.json"
			];
		};
	};
}
