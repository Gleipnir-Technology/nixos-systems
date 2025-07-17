{ config, configPath, lib, pkgs, ... }:

with lib;

{
	options.myModules.fish.enable = mkEnableOption "custom fish configuration";
	config = mkIf config.myModules.fish.enable {
		environment.systemPackages = [ pkgs.fish ];
	};
}
