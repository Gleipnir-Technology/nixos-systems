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
	nidus-name-dev = "nidus-dev-sync";
in {
	environment = pkgs.lib.mkMerge [ fss-deltamvcd.environment fss-gleipnir-qa.environment ];
	services = pkgs.lib.mkMerge [
		fss-deltamvcd.services
		fss-gleipnir-qa.services

		{
			caddy.virtualHosts."dev-sync.nidus.cloud".extraConfig = ''
				reverse_proxy http://127.0.0.1:9002
			'';
			postgresql = {
				enable = true;
				ensureDatabases = [nidus-name-dev];
				ensureUsers = [{
					ensureClauses.login = true;
					ensureDBOwnership = true;
					name = nidus-name-dev;
				} {
					ensureClauses.login = true;
					ensureDBOwnership = true;
					name = nidus-name-dev;
				}];
			};
		}

	];
	sops = pkgs.lib.mkMerge [
		fss-deltamvcd.sops
		fss-gleipnir-qa.sops  
		{
			secrets."nidus-dev-sync-env" = {
				format = "dotenv";
				group = nidus-name-dev;
				mode = "0440";
				owner = nidus-name-dev;
				restartUnits = [];
				sopsFile = ../secrets/${nidus-name-dev}.env;
			};
		}
	];
	systemd = pkgs.lib.mkMerge [ fss-deltamvcd.systemd fss-gleipnir-qa.systemd ];
	users = pkgs.lib.mkMerge [
		fss-deltamvcd.users
		fss-gleipnir-qa.users

		{
			groups."${nidus-name-dev}" = {};
			users."${nidus-name-dev}" = {
				group = nidus-name-dev;
				isSystemUser = true;
			};
		}

	];

	myModules.asterisk.enable = true;
	myModules.caddy.enable = true;
	myModules.nidus-sync.enable = true;
}
