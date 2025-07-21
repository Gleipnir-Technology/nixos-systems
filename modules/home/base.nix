{ config, configFiles, lib, pkgs, ... }:

with lib;

{
	options.myModules.home.user = mkOption {
		description = "The username of the user for building paths";
		type = types.str;
	};
}
