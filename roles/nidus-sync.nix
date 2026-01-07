{ inputs, lib, pkgs, ...}:
let
	fss-deltamvcd = import ../modules/system/fieldseeker-sync.nix {
		customer = "deltamvcd";
		dataDirectory = /mnt/bigdisk/fieldseeker-sync/deltamvcd;
		fieldseeker-sync = inputs.fieldseeker-sync;
		port = 3000;
		subdomain = "deltamvcd";
		inherit lib pkgs;
	};
in {
	environment = pkgs.lib.mkMerge [ fss-deltamvcd.environment ];
	services = pkgs.lib.mkMerge [
		fss-deltamvcd.services
	];
	sops = pkgs.lib.mkMerge [
		fss-deltamvcd.sops
	];
	systemd = pkgs.lib.mkMerge [ fss-deltamvcd.systemd ];
	users = pkgs.lib.mkMerge [
		fss-deltamvcd.users
	];

	myModules.asterisk.enable = false;
	myModules.caddy.enable = true;
	myModules.qgis.enable = false;
	myModules.nidus-sync.enable = true;
	myModules.tegola.enable = true;
}
