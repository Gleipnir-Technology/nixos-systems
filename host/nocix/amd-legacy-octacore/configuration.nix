{ lib, modulesPath, pkgs, ... } @ args: {
	imports = [
		./network.nix
	];

	environment.systemPackages = with pkgs; [
		age
		fish
		git
		htop
		neovim
		podman
		postgresql
		redis
		slirp4netns
		tmux
		wget
	];
	services.openssh.enable = true;
	services.postgresql.enable = true;
	zramSwap.enable = true;

	system.stateVersion = "25.05";
}
