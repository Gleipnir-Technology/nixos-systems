{ config, lib, pkgs, ... }:
with lib;

let
	cfg = config.services.forgejo;
	srv = cfg.settings.server;
{
	options.myModules.forgejo.enable = mkEnableOption "custom forgejo configuration";

	config = mkIf config.myModules.forgejo.enable {
		services.forgejo = {
			database.type = "postgres";
			enable = true;
			# Enable support for Git Large File Storage
			lfs.enable = true;
			settings = {
				# Add support for actions, based on act: https://github.com/nektos/act
				actions = {
					ENABLED = false;
					DEFAULT_ACTIONS_URL = "github";
				};
				# Sending emails is completely optional
				# You can send a test email from the web UI at:
				# Profile Picture > Site Administration > Configuration >  Mailer Configuration 
				#mailer = {
					#ENABLED = false;
					#SMTP_ADDR = "mail.example.com";
					#FROM = "noreply@${srv.DOMAIN}";
					#USER = "noreply@${srv.DOMAIN}";
				#};
				server = {
					DOMAIN = "source.gleipnir.technology";
					# You need to specify this to remove the port from URLs in the web UI.
					HTTP_ADDR = "/var/run/forgejo/socket";
					PROTOCOL = "http+unix";
					ROOT_URL = "https://${srv.DOMAIN}/"; 
				};
				# You can temporarily allow registration to create an admin user.
				service.DISABLE_REGISTRATION = true; 
				# Enable ssh user for 'git push'
				ssh = {
					PORT = 22;
				};
			};
			stateDir = "/mnt/bigdisk/forgejo";
			#mailerPasswordFile = config.age.secrets.forgejo-mailer-password.path;
		};
		systemd.tmpfiles.rules = [
		  "d  /var/run/forgejo           0750 forgejo forgejo - -"
		];
	};
}
