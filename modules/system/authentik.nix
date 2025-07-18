{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.authentik.enable = mkEnableOption "custom authentik configuration";

	config = mkIf config.myModules.authentik.enable {
		sops.secrets.authentik-env = with config.virtualisation.oci-containers; {
			format = "dotenv";
			group = "authentik";
			mode = "0440";
			owner = "authentik";
			restartUnits = ["${backend}-authentik-server" "${backend}-authentik-worker"];
			sopsFile = ../../secrets/authentik.env;
		};
		systemd.services.podman-create-authentik-pod = with config.virtualisation.oci-containers; {
			serviceConfig.Type = "oneshot";
			wantedBy = [ "${backend}-authentik-server.service" "${backend}-authentik-worker.service"];
			script = ''
				${pkgs.podman}/bin/podman pod exists authentik || \
				  ${pkgs.podman}/bin/podman pod create \
				    --name authentik \
				    -p 127.0.0.1:10000:9000
			'';
		};
		systemd.tmpfiles.rules = [
			"d /opt/authentik/certs 0755 authentik authentik"
			"d /opt/authentik/media 0755 authentik authentik"
			"d /opt/authentik/templates 0755 authentik authentik"
		];
		users.groups.authentik = {};
		users.users.authentik = {
			group = "authentik";
			isNormalUser = false;
			isSystemUser = true;
		};
		virtualisation.oci-containers.containers = {
			authentik-server = {
				cmd = ["server"];
				environmentFiles = [
					"/var/run/secrets/authentik-env"
				];
				extraOptions = [ "--pod=authentik" ];
				image = "ghcr.io/goauthentik/server:2025.4";
				volumes = [
					"/opt/authentik/media:/media"
					"/opt/authentik/templates:/templates"
				];
			};
			authentik-worker = {
				cmd = ["worker"];
				environmentFiles = [
					"/var/run/secrets/authentik-env"
				];
				extraOptions = [ "--pod=authentik" ];
				image = "ghcr.io/goauthentik/server:2025.4";
				volumes = [
					"/opt/authentik/certs:/certs"
					"/opt/authentik/media:/media"
					"/opt/authentik/templates:/templates"
				];
			};
		};
	};
}
