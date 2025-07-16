{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	options.myModules.home.neovim = {
		enable = mkEnableOption "custom neovim configuration";
		user = mkOption {
			type = types.str;
			description = "Username for user-specific config";
		};
	};

	config = mkIf config.myModules.home.neovim.enable (
		let
			userConfigPath = "${configFiles}/users/${config.myModules.home.neovim.user}/nvim";
			sharedConfigPath = "${configFiles}/shared/nvim";
			
			# Use user-specific config if it exists, otherwise fall back to shared
			configPath = if builtins.pathExists (configFiles + "/users/${config.myModules.home.neovim.user}/nvim")
						 then userConfigPath
						 else sharedConfigPath;
		in {
			programs.neovim.enable = true;
			
			# Use the correct Home Manager option
			home.file.".config/nvim" = {
				source = configPath;
				recursive = true;
			};
		}
	);
}
