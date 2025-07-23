{ config, lib, pkgs, configPath, ... }:

with lib;

{
	options.myModules.cloudreve.enable = mkEnableOption "custom cloudreve configuration";

	config = mkIf config.myModules.cloudreve.enable {
		services.caddy.virtualHosts."files.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10040
		'';
		sops.secrets.cloudreve-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "cloudreve";
			mode = "0440";
			owner = "cloudreve";
			restartUnits = ["${backend}-cloudreve"];
			sopsFile = ../../secrets/cloudreve.env;
		};
		systemd.tmpfiles.rules = [
			"d /opt/cloudreve 0755 cloudreve cloudreve"
		];
		virtualisation.oci-containers.containers.cloudreve = {
			environmentFiles = [
				"/var/run/secrets/cloudreve-env"
			];
			image = "cloudreve.azurecr.io/cloudreve/pro:4.3.0";
			ports = [ "127.0.0.1:10040:5212" ];
			volumes = [
				"/opt/cloudreve:/cloudreve/data"
			];
		};
		users.groups.cloudreve = {};
		users.users.cloudreve = {
			group = "cloudreve";
			isSystemUser = true;
		};
	};
}
