{ config, configFiles, lib, pkgs, ... }:

with lib;

{
	options.myModules.home.git = {
		enable = mkEnableOption "custom git configuration";
	};

	config = mkIf config.myModules.home.git.enable (
		let
			configPath = (configFiles + "/users/${config.myModules.home.user}/gitconfig");
		in {
			# Use the correct Home Manager option
			home.file.".gitconfig" = {
				source = configPath;
			};
		}
	);
}
