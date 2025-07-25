{ config, configFiles, lib, pkgs, ... }:

with lib;

{
	options.myModules.home.fish = {
		enable = mkEnableOption "custom fish configuration";
	};

	config = mkIf config.myModules.home.fish.enable (
		let
			# Use user-specific config if it exists, otherwise fall back to shared
			configPath = (configFiles + "/users/${config.myModules.home.user}/fish");
		in {
			# Use the correct Home Manager option
			home.file.".config/fish" = {
				source = configPath;
				recursive = true;
			};
			programs.fish = {
				enable = true;
			};
		}
	);
}
