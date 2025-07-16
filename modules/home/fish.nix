{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	options.myModules.home.fish = {
		enable = mkEnableOption "custom fish configuration";
		user = mkOption {
			type = types.str;
			description = "Username for user-specific config";
		};
	};

	config = mkIf config.myModules.home.fish.enable (
		let
			userConfigPath = "${configFiles}/users/${config.myModules.home.fish.user}/fish";
			
			# Use user-specific config if it exists, otherwise fall back to shared
			configPath = (configFiles + "/users/${config.myModules.home.fish.user}/fish");
		in {
			# Use the correct Home Manager option
			home.file.".config/fish" = {
				source = configPath;
				recursive = true;
			};
		}
	);
}
