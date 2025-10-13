{ config, lib, pkgs, ... }: {
	myModules.caddy.enable = true;
	myModules.frps.enable = true;
}
