{ config, lib, pkgs, ... }: {
	imports = [
		./hardware-configuration.nix
		./networking.nix # generated at runtime by nixos-infect
	];

	myModules = {
		authentik.enable = true;
		cloud-init.enable = true;
		do-agent.enable = true;
		podman.enable = true;
	};
}
