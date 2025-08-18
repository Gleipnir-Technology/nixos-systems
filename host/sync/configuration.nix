{ config, lib, pkgs, ... }: {
	imports = [
		./hardware-configuration.nix
	];
	myModules.fieldseeker-sync.enable = true;
}
