{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	options.myModules.tmux.enable = mkEnableOption "custom tmux configuration";

	config = mkIf config.myModules.tmux.enable {
		environment.systemPackages = [ pkgs.tmux ];

		environment.etc."tmux.conf".source = "${configFiles}/tmux/tmux.conf";

		# Alternative: if you want per-user configs
		# users.users = mkMerge (map (user: {
		#	 ${user}.home = "${configPath}/configs/tmux/tmux.conf";
		# }) config.myModules.tmux.users);
	};
}
