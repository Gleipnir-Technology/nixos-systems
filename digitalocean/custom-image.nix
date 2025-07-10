let
	## Pin the latest NixOS stable (nixos-25.05) release:
	nixpkgs = builtins.fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
		sha256 = "sha256:1915r28xc4znrh2vf4rrjnxldw2imysz819gzhk9qlrkqanmfsxd";
	};

	## Import nixpkgs:
	pkgs = import nixpkgs { };

	## Prepare the NixOS configuration:
	config = {
		imports = [
			"${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
		];
		system.stateVersion = "25.05";
		users.users.eliribble = {
			extraGroups = [ "sudo" "wheel" ];
			initialHashedPassword = "$y$j9T$XYOMZR8RZEiTnpaF8lsxv1$H7YbWDpzbnYXTLN0ZMhvtKOlSMy64P7C/RdLBaeaNf/";
			isNormalUser = true;
			openssh.authorizedKeys.keys = [
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHL1SpT3KR8XeXtH19muncYVrKxWzWdWtJYNTwoJGTm3 eliribble@Elis-Mac-mini.local"
			];
		};
		users.users.root.openssh.authorizedKeys.keys = [
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHL1SpT3KR8XeXtH19muncYVrKxWzWdWtJYNTwoJGTm3 eliribble@Elis-Mac-mini.local"
		];
	};
in
(pkgs.nixos config).digitalOceanImage
