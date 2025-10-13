{ config, configFiles, inputs, lib, pkgs, ... }:
with lib;
{
	options.myModules.frps.enable = mkEnableOption "custom frps configuration";
	config = mkIf config.myModules.frps.enable {
		environment.etc."frps.toml".source = "${configFiles}/frps/frps.toml";
	};
}
