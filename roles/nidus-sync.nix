{ config, lib, pkgs, ... }: {
	myModules.caddy.enable = true;
	myModules.fieldseeker-sync.enable = true;
}
