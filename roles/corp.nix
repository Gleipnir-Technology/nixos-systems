{ config, lib, pkgs, ... }: {
	myModules = {
		authentik.enable = true;
		caddy.enable = true;
		cloudreve.enable = true;
		collabora.enable = true;
		glitchtip.enable = false;
		element-web.enable = true;
		label-studio.enable = true;
		librechat.enable = true;
		minio.enable = true;
		static-websites.enable = true;
		synapse.enable = true;
		timecardbot.enable = true;
		twenty-crm.enable = true;
		vikunja.enable = true;
	};
}
