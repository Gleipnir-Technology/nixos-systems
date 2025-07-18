{ pkgs, lib, config, ... }:
with lib;
{
	options.myModules.authentik.enable = mkEnableOption "custom authentik configuration";

	config = mkIf config.myModules.authentik.enable {
		sops.secrets.authentik-env = {
			format = "env";
			group = "authentik";
			mode = "0440";
			owner = "authentik";
			restartUnits = ["authentik"];
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
