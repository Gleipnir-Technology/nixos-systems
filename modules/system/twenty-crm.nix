{ pkgs, lib, config, ... }:
with lib;
let
	tag = "v1.8.2";
	port = "10090";
in {
	options.myModules.twenty-crm.enable = mkEnableOption "custom twenty-crm configuration";

	config = mkIf config.myModules.twenty-crm.enable {
		services.caddy.virtualHosts."crm.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:${port}
		'';
		services.postgresql = {
			ensureDatabases = [ "twenty_crm" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "twenty_crm";
			}];
		};
		sops.secrets.twenty-crm-env = {
			format = "dotenv";
			group = "twenty-crm";
			mode = "0440";
			owner = "twenty-crm";
			restartUnits = ["podman-twenty-crm.service"];
			sopsFile = ../../secrets/twenty-crm.env;
		};
		users.groups.twenty-crm = {};
		users.users.twenty-crm = {
			group = "twenty-crm";
			isSystemUser = true;
		};
		virtualisation.oci-containers.containers.twenty-crm-webserver = {
			environmentFiles = [
				"/var/run/secrets/twenty-crm-env"
			];
			image = "docker.io/twentycrm/twenty:${tag}";
			ports = [ "127.0.0.1:3000:${port}" ];
			volumes = [
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
				"twenty-crm-data:/app/packages/twenty-server/.local-storage"
			];
		};
		virtualisation.oci-containers.containers.twenty-crm-worker = {
			entrypoint = "yarn worker:prod";
			environmentFiles = [
				"/var/run/secrets/twenty-crm-env"
			];
			image = "docker.io/twentycrm/twenty:${tag}";
			ports = [ "127.0.0.1:3000:${port}" ];
			volumes = [
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
				"twenty-crm-data:/app/packages/twenty-server/.local-storage"
			];
		};
	};
}
