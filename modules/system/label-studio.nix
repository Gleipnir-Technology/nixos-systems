{ lib, config, nixpkgs, pkgs, ... }:
with lib;
{
	options.myModules.label-studio.enable = mkEnableOption "custom label-studio configuration";

	config = mkIf config.myModules.label-studio.enable {
		services.postgresql = {
			ensureDatabases = [ "label-studio" ];
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "label-studio";
			}];
		};
		sops.secrets.label-studio-env = {
			format = "dotenv";
			group = "label-studio";
			mode = "0440";
			owner = "label-studio";
			restartUnits = ["podman-label-studio.service"];
			sopsFile = ../../secrets/label-studio.env;
		};
		systemd.tmpfiles.rules = [
			"d /mnt/bigdisk/label-studio 0755 label-studio label-studio"
		];
		virtualisation.oci-containers.containers.label-studio = {
			environmentFiles = [
				"/var/run/secrets/label-studio-env"
			];
			extraOptions = [
				"--userns=keep-id:uid=1001,gid=0"
			];
			image = "docker.io/heartexlabs/label-studio:1.21.0";
			ports = [ "127.0.0.1:10070:8080" ];
			volumes = [
				"/mnt/bigdisk/label-studio:/label-studio/data"
				"/run/postgresql/.s.PGSQL.5432:/run/postgresql/.s.PGSQL.5432"
			];
		};
		users.groups.label-studio = {};
		users.users.label-studio = {
			uid = 1001;
			group = "label-studio";
			isSystemUser = true;
		};
	};
}
