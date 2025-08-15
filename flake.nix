{
	description = "Multi-host NixOS configuration";

	inputs = {
		home-manager = {
			url = "github:nix-community/home-manager/release-25.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		nixvim = {
			url = "github:nix-community/nixvim/nixos-25.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix.url = "github:Mic92/sops-nix";
	};

	outputs = { self, home-manager, nixpkgs, nixvim, sops-nix, ...}:
		let
			configFiles = pkgs.stdenv.mkDerivation {
			name = "config-files";
				src = ./configs;
				installPhase = ''
					mkdir -p $out
					cp -r * $out/
				'';
			};
			pkgs = nixpkgs.legacyPackages.${system};
			system = "x86_64-linux";
		in {
			nixosConfigurations = {
				corp = import ./system.nix {
					configuration = ./host/corp/configuration.nix;
					inherit configFiles;
					inherit home-manager;
					inherit nixpkgs;
					inherit nixvim;
					inherit sops-nix;
					inherit system;
				};
				"sync.nidus.cloud" = import ./system.nix {
					configuration = ./host/sync/configuration.nix;
					inherit configFiles;
					inherit home-manager;
					inherit nixpkgs;
					inherit nixvim;
					inherit sops-nix;
					inherit system;
				};
				test-corp = nixpkgs.lib.nixosSystem {
					configuration = ./host/test-corp/configuration.nix;
					inherit configFiles;
					inherit home-manager;
					inherit nixpkgs;
					inherit nixvim;
					inherit sops-nix;
					inherit system;
				};
			};
		};
}
