{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	options.myModules.cloud-init.enable = mkEnableOption "custom cloud-init configuration";
	config = mkIf config.myModules.cloud-init.enable {
		services.cloud-init = {
			enable = true;
			network.enable = true;
		};
	};
}
