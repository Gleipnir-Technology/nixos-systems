{
	description = "Multi-host NixOS configuration";

	inputs = {
		authentik-nix = {
			url = "github:nix-community/authentik-nix";
		};
		disko = {
			inputs.nixpkgs.follows = "nixpkgs";
			url = "github:nix-community/disko";
		};
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
		timecard-bot.url = "github:Gleipnir-Technology/timecard-bot?rev=8c81b6683f97aa2712323836e629adf102be58ac";
	};

	outputs = { self, authentik-nix, disko, home-manager, nixpkgs, nixvim, sops-nix, timecard-bot, ...}:
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
					inherit authentik-nix configFiles disko home-manager nixpkgs nixvim sops-nix system timecard-bot;
				};
				"nocix-amd-legacy-hexcore" = import ./system.nix {
					configuration = ./host/nocix/amd-legacy-hexcore;
					roles = [ ./roles/nidus-sync.nix ];
					inherit authentik-nix configFiles disko home-manager nixpkgs nixvim sops-nix system timecard-bot;
				};
				"sync.nidus.cloud" = import ./system.nix {
					configuration = ./host/sync/configuration.nix;
					inherit authentik-nix configFiles disko home-manager nixpkgs nixvim sops-nix system timecard-bot;
				};
				test-corp = nixpkgs.lib.nixosSystem {
					configuration = ./host/test-corp/configuration.nix;
					inherit authentik-nix configFiles disko home-manager nixpkgs nixvim sops-nix system timecard-bot;
				};
			};
		};
}
