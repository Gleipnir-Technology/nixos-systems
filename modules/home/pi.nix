{ config, configFiles, lib, pkgs, ... }:

with lib;

{
	options.myModules.home.pi = {
		enable = mkEnableOption "custom pi agent configuration";
	};

	config = mkIf config.myModules.home.pi.enable (
		let
			# Use user-specific config if it exists
			configPath = (configFiles + "/users/${config.myModules.home.user}/pi");
		in {
			# Use the correct Home Manager option
			home.file.".pi" = {
				source = configPath;
				recursive = true;
			};
		}
	);
}
