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
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
	};

	outputs =
		{
			disko,
			home-manager,
			nixpkgs,
			nixos-facter-modules,
			...
		}:
		let
			configFiles = pkgs.stdenv.mkDerivation {
				installPhase = ''
					mkdir -p $out
					cp -r * $out/
				'';
				name = "config-files";
				src = ./configs;
			};
			pkgs = nixpkgs.legacyPackages.${system};
			system = "x86_64-linux";
		in {
			# tested with 2GB/2CPU droplet, 1GB droplets do not have enough RAM for kexec
			nixosConfigurations.digitalocean = nixpkgs.lib.nixosSystem {
				system = "${system}";
				modules = [
					./configuration.nix
					./digitalocean.nix
					disko.nixosModules.disko
					{ disko.devices.disk.disk1.device = "/dev/vda"; }
					home-manager.nixosModules.home-manager {
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.sharedModules = [];
						home-manager.extraSpecialArgs = { inherit configFiles; };
					}
					./modules
					./users
				];
			};
		};
}
