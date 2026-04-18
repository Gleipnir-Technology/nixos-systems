{ inputs, lib, pkgs, ...}:
{
	environment.systemPackages = [
		pkgs.google-chrome

		# Create a wrapper for google-chrome command
		(pkgs.writeShellScriptBin "google-chrome" ''
			exec ${pkgs.google-chrome}/bin/google-chrome-stable "$@"
		'')
	];
	fonts.packages = with pkgs; [
		corefonts
		liberation_ttf
	];
	fonts.fontDir.enable = true;
	myModules.asterisk.enable = false;
	myModules.caddy.enable = true;
	myModules.qgis.enable = false;
	myModules.nidus-sync.enable = true;
	myModules.restic.role = "nidus";
	myModules.tegola.enable = true;
}
