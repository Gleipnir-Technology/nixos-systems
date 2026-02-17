{ inputs, lib, pkgs, ...}:
{
	myModules.asterisk.enable = false;
	myModules.caddy.enable = true;
	myModules.qgis.enable = false;
	myModules.nidus-sync.enable = true;
	myModules.restic.role = "nidus";
	myModules.tegola.enable = true;
}
