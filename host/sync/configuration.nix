{ config, lib, pkgs, ... }: {
	imports = [
		./hardware-configuration.nix
	];
	myModules.caddy.enable = true;
	myModules.fieldseeker-sync.enable = true;
}
