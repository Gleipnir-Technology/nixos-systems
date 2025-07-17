{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	options.myModules.do-agent.enable = mkEnableOption "custom do-agent configuration";

	config = mkIf config.myModules.do-agent.enable {
		services.do-agent.enable = true;
	};
}
