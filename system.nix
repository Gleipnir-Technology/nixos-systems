{ configFiles, configuration, disko, home-manager, inputs, nixpkgs, nixvim, roles, sops-nix, system, timecard-bot, ... }:
let 
	allowed-unfree-packages = [
		"corefonts"
		"mongodb"
	];
in nixpkgs.lib.nixosSystem {
	modules = [
		inputs.authentik-nix.nixosModules.default
		disko.nixosModules.disko
		home-manager.nixosModules.home-manager
		{
			home-manager.extraSpecialArgs = { inherit configFiles inputs; };
			home-manager.sharedModules = [
				nixvim.homeManagerModules.nixvim
				./modules/home/nixvim.nix
			];
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
		}
		configuration
		./modules
		sops-nix.nixosModules.sops {
			sops = {
				age.generateKey = true;
				age.keyFile = "/var/libs/sops-nix/key.txt";
				age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
				defaultSopsFile = ./secrets/secrets.yaml;
			};
		}
		./users
	] ++ roles;
	pkgs = import nixpkgs {
		config = {
			allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) allowed-unfree-packages;
		};
		system = "${system}";
	};
	specialArgs = {
		inherit configFiles inputs timecard-bot;
	};
	system = "${system}";
}
