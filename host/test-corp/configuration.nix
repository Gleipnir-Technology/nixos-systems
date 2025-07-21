{ config, lib, pkgs, ... }: {
	imports = [
		./hardware-configuration.nix
		./networking.nix # generated at runtime by nixos-infect
	];

	myModules = {
		authentik.enable = false;
		caddy.enable = true;
		cloud-init.enable = false;
		do-agent.enable = true;
		librechat.enable = true;
		podman.enable = true;
		sillytavern.enable = false;
	};
}
