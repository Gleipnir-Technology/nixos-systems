{
	description = "Multi-host NixOS configuration";

	inputs = {
		authentik-nix = {
			inputs.nixpkgs.follows = "nixpkgs";
			url = "github:nix-community/authentik-nix";
		};
		disko = {
			inputs.nixpkgs.follows = "nixpkgs";
			url = "github:nix-community/disko";
		};
		home-manager = {
			url = "github:nix-community/home-manager/release-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		llm-agents.url = "github:numtide/llm-agents.nix";
		nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		nixvim = {
			url = "github:nix-community/nixvim/nixos-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix.url = "github:Mic92/sops-nix";
	};

	outputs = inputs@{ self, disko, home-manager, nixpkgs, nixvim, sops-nix, ...}:
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
			nixosConfigurations = {
				"nocix-amd-legacy-quadcore-292465" = import ../system.nix {
					configuration = ../host/nocix/amd-legacy-quadcore-292465;
					roles = [../roles/llm.nix ];
					inherit configFiles disko home-manager inputs nixpkgs nixvim sops-nix system;
				};
			};
		};
}
