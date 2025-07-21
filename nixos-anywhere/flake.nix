{
	inputs = {
		disko = {
			inputs.nixpkgs.follows = "nixpkgs";
			url = "github:nix-community/disko";
		};
		home-manager = {
			url = "github:nix-community/home-manager/release-25.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		sops-nix.url = "github:Mic92/sops-nix";
	};

	outputs =
		{
			disko,
			home-manager,
			nixpkgs,
			nixos-facter-modules,
			sops-nix,
			...
		}:
		let
			configFiles = pkgs.stdenv.mkDerivation {
				installPhase = ''
					mkdir -p $out
					cp -r * $out/
				'';
				name = "config-files";
				src = ../configs;
			};
			pkgs = nixpkgs.legacyPackages.${system};
			system = "x86_64-linux";
		in {
			# tested with 2GB/2CPU droplet, 1GB droplets do not have enough RAM for kexec
			nixosConfigurations.digitalocean = nixpkgs.lib.nixosSystem {
				modules = [
					./configuration.nix
					./digitalocean.nix
					disko.nixosModules.disko
					{ disko.devices.disk.disk1.device = "/dev/vda"; }
					home-manager.nixosModules.home-manager {
						home-manager.extraSpecialArgs = { inherit configFiles; };
						home-manager.sharedModules = [];
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
					}
					../modules
					sops-nix.nixosModules.sops {
						sops = {
							age.generateKey = true;
							age.keyFile = "/var/libs/sops-nix/key.txt";
							age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
							defaultSopsFile = ./secrets/secrets.yaml;
						};
					}
					../users
				];
				specialArgs = {
					inherit configFiles;
				};
				system = "${system}";
			};
		};
}
