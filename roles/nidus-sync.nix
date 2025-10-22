{ inputs, lib, pkgs, ...}:
let
	fss-deltamvcd = import ../modules/system/fieldseeker-sync.nix {
		customer = "deltamvcd";
		dataDirectory = /opt/fieldseeker-sync/deltamvcd;
		fieldseeker-sync = inputs.fieldseeker-sync;
		port = 3000;
		subdomain = "deltamvcd";
		inherit lib pkgs;
	};
	fss-gleipnir-qa = import ../modules/system/fieldseeker-sync.nix {
		customer = "gleipnir-qa";
		dataDirectory = /opt/fieldseeker-sync/gleipnir;
		fieldseeker-sync = inputs.fieldseeker-sync;
		port = 3001;
		subdomain = "gleipnir-qa";
		inherit lib pkgs;
	};
in {
	environment = pkgs.lib.mkMerge [ fss-deltamvcd.environment fss-gleipnir-qa.environment ];
	services = pkgs.lib.mkMerge [ fss-deltamvcd.services fss-gleipnir-qa.services ];
	sops = pkgs.lib.mkMerge [ fss-deltamvcd.sops fss-gleipnir-qa.sops ];
	systemd = pkgs.lib.mkMerge [ fss-deltamvcd.systemd fss-gleipnir-qa.systemd ];
	users = pkgs.lib.mkMerge [ fss-deltamvcd.users fss-gleipnir-qa.users ];
	myModules.caddy.enable = true;
}
