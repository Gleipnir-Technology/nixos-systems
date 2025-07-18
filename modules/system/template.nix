{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.template.enable = mkEnableOption "custom template configuration";

	config = mkIf config.myModules.template.enable {
		#environment.systemPackages = with pkgs; [
			#template
		#];
	};
}
