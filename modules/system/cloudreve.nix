{ config, lib, pkgs, configPath, ... }:

with lib;

{
	options.myModules.cloudreve.enable = mkEnableOption "custom cloudreve configuration";

	config = mkIf config.myModules.cloudreve.enable {
		virtualisation.oci-containers.containers.cloudreve = {
			environment = {
				"CR_CONF_Database.Type" = "postgres";
				"CR_CONF_Database.DatabaseURL" = "postgresql:///cloudreve?host=/run/postgresql/&user=cloudreve";
			};
			image = "cloudreve.azurecr.io/cloudreve/pro:4.3.0
			ports = [ "127.0.0.1:10040:5212" ];
			volumes = [
				"/var/lib/cloudreve:/cloudreve/data"
			];
		};
	};
}
