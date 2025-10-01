{ lib, config, nixpkgs, pkgs, ... }:
with lib;
{
	options.myModules.minio.enable = mkEnableOption "custom minio configuration";
	config = mkIf config.myModules.minio.enable {
		services.caddy.virtualHosts."s3.gleipnir.technology".extraConfig = ''
			reverse_proxy http://localhost:10080
		'';
		services.minio = {
			certificatesDir = "/mnt/bigdisk/minio/certificates";
			configDir = "/mnt/bigdisk/minio/config";
			consoleAddress = "127.0.0.1:10080";
			enable = true;
			dataDir = ["/mnt/bigdisk/minio/data"];
			rootCredentialsFile = "/var/run/secrets/minio-env";
		};
		sops.secrets.minio-env = {
			format = "dotenv";
			group = "minio";
			mode = "0440";
			owner = "minio";
			restartUnits = ["minio.service"];
			sopsFile = ../../secrets/minio.env;
		};
		#systemd.tmpfiles.rules = [
			#"d /mnt/bigdisk/minio 0755 minio minio"
		#];
	};
}
