{ config, lib, pkgs, ... }: {
	imports = [
		./hardware-configuration.nix
		./networking.nix # generated at runtime by nixos-infect
	];

	myModules = {
		cloud-init.enable = true;
		do-agent.enable = true;
	};
	virtualisation.podman.enable = true;
}
