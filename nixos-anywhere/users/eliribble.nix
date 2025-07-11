{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	home-manager.users.eliribble = { pkgs, ... }: {
		imports = [ ../modules/home ];

		home.stateVersion = "25.05";
	};

	users.users.eliribble = {
		extraGroups = [ "docker" "wheel" ];
		isNormalUser = true;
		initialHashedPassword = "$y$j9T$pXXR8iNU81XAghZWEXVrC/$Xp4nL6FrTAZ3DnJkcx.zi0q2SGk8KUz8YfejkAoWSE.";
		openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHL1SpT3KR8XeXtH19muncYVrKxWzWdWtJYNTwoJGTm3 eliribble@Elis-Mac-mini.local"
		];
	};
}
