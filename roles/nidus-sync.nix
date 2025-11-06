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
	fss-gleipnir-qa = import ../modules/system/fieldseeker-sync.nix {
		customer = "gleipnir-qa";
		dataDirectory = /mnt/bigdisk/fieldseeker-sync/gleipnir-qa;
		fieldseeker-sync = inputs.fieldseeker-sync;
		port = 3001;
		subdomain = "gleipnir-qa";
		inherit lib pkgs;
	};
	nidus-name = "nidus-sync";
in {
	environment = pkgs.lib.mkMerge [ fss-deltamvcd.environment fss-gleipnir-qa.environment ];
	services = pkgs.lib.mkMerge [
		fss-deltamvcd.services
		fss-gleipnir-qa.services

		{
			caddy.virtualHosts."sync.nidus.cloud".extraConfig = ''
				reverse_proxy http://127.0.0.1:9001
			'';
			postgresql = {
				enable = true;
				ensureDatabases = [nidus-name];
				ensureUsers = [{
					ensureClauses.login = true;
					ensureDBOwnership = true;
					name = nidus-name;
				}];
			};
		}

	];
	sops = pkgs.lib.mkMerge [ fss-deltamvcd.sops fss-gleipnir-qa.sops ];
	systemd = pkgs.lib.mkMerge [ fss-deltamvcd.systemd fss-gleipnir-qa.systemd ];
	users = pkgs.lib.mkMerge [
		fss-deltamvcd.users
		fss-gleipnir-qa.users

		{
			groups."${nidus-name}" = {};
			users."${nidus-name}" = {
				group = nidus-name;
				isSystemUser = true;
			};
		}

	];


	myModules.caddy.enable = true;
}
