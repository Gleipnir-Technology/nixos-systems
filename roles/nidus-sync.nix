{ config, lib, pkgs, ... }: {
	myModules.caddy.enable = true;
	myModules.fieldseeker-sync.deployments = [{
		customer = "deltamvcd";
		#database = "fieldseeker-sync";
		dataDirectory = /opt/fieldseeker-sync/deltamvcd;
		port = 3000;
		subdomain = "deltamvcd";
	} {
		customer = "gleipnir-qa";
		#database = "fieldseeker-sync-gleipnir";
		dataDirectory = /opt/fieldseeker-sync/gleipnir;
		port = 3001;
		subdomain = "gleipnir-qa";
	}];
}
