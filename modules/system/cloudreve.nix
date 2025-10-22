{ config, lib, pkgs, configPath, ... }:

with lib;

{
	options.myModules.cloudreve.enable = mkEnableOption "custom cloudreve configuration";

	config = mkIf config.myModules.cloudreve.enable {
		services.caddy.virtualHosts."files.gleipnir.technology".extraConfig = ''
			reverse_proxy http://127.0.0.1:10040
		'';
		services.postgresql = {
			# In the below config I've got 107.150.59.1/24, which is a total guess
			# based on what I'm seeing with containers, it may be way, WAY off.
			authentication = pkgs.lib.mkOverride 10 ''
				#type database  DBuser     origin-address auth-method
				local all       all        trust
				host  all       all        127.0.0.1/32    trust
				host  all       all        ::1/128         trust
				host  cloudreve cloudreve  10.88.0.1/16    trust
				host  cloudreve cloudreve  107.150.59.1/24 trust
				host  twenty_crm twenty_crm  10.88.0.1/16    trust
				host  twenty_crm twenty_crm  107.150.59.1/24 trust
			'';
			enable = true;
			ensureDatabases = [ "cloudreve" ];
			enableTCPIP = true;
			ensureUsers = [{
				ensureClauses.login = true;
				ensureDBOwnership = true;
				name = "cloudreve";
			}];
			#settings = {
				#listen_addresses = lib.mkForce "10.88.0.1,localhost";
			#};
		};
		sops.secrets.cloudreve-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "cloudreve";
			mode = "0440";
			owner = "cloudreve";
			restartUnits = ["${backend}-cloudreve"];
			sopsFile = ../../secrets/cloudreve.env;
		};
		systemd.tmpfiles.rules = [
			"d /opt/cloudreve 0755 cloudreve cloudreve"
		];
		# The container here comes from a private repository. In order to get it you need to buy a pro license
		# and download and configure the image via https://cloudreve.org/manage
		# You'll do so by getting the image repository credentials and running
		#   sudo podman login -u <user> -p <password> cloudreve.azurecr.io
		virtualisation.oci-containers.containers.cloudreve = {
			environmentFiles = [
				"/var/run/secrets/cloudreve-env"
			];
			#extraOptions = ["--network=pasta:--map-gw"];
			image = "cloudreve.azurecr.io/cloudreve/pro:4.7.0";
			# I'd much rather be doing this, but it fails in inscrutible ways
			#podman.user = "cloudreve";
			ports = [ "127.0.0.1:10040:5212" ];
			volumes = [
				"/mnt/bigdisk/cloudreve:/cloudreve/data"
			];
		};
		users.groups.cloudreve = {};
		users.users.cloudreve = {
			group = "cloudreve";
			home = "/home/cloudreve";
			isSystemUser = true;
		};
	};
}
