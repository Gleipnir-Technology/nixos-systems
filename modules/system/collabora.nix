{ config, lib, pkgs, configPath, ... }:

with lib;

{
	options.myModules.collabora.enable = mkEnableOption "custom collabora configuration";

	config = mkIf config.myModules.collabora.enable {
		services.caddy.virtualHosts."collabora.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10020
		'';
		virtualisation.oci-containers.containers.collabora = {
			image = "collabora/code";
			ports = [ "127.0.0.1:10020:9980" ];
			environment = {
				domain = "collabora.gleipnir.technology";
				extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
			};
			extraOptions = [
				"--cap-add"
				"MKNOD"
			];
		};
	};
}
