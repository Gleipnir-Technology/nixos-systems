{ config, configFiles, lib, pkgs, ... }:

with lib;
{
	options.myModules.podman.enable = mkEnableOption "custom podman configuration";
	config = mkIf config.myModules.podman.enable {
		virtualisation.podman.enable = true;
	};
}
