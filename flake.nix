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
		fieldseeker-sync = {
			type = "github";
			owner = "Gleipnir-Technology";
			repo = "fieldseeker-sync";
			rev = "e250e0abbb35f6d64851305d3b59c4ed1d968bc8";
		};
		home-manager = {
			url = "github:nix-community/home-manager/release-25.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nidus-sync = {
			type = "github";
			owner = "Gleipnir-Technology";
			repo = "nidus-sync";
			rev = "0a74bd83454c5a07444849e08395ca220aa5ef62";
		};
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
		nixvim = {
			url = "github:nix-community/nixvim/nixos-25.05";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix.url = "github:Mic92/sops-nix";
		timecard-bot.url = "github:Gleipnir-Technology/timecard-bot?rev=8c81b6683f97aa2712323836e629adf102be58ac";
	};

	outputs = inputs@{ self, disko, home-manager, nixpkgs, nixvim, sops-nix, timecard-bot, ...}:
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
				"nocix-amd-legacy-octacore" = import ./system.nix {
					configuration = ./host/nocix/amd-legacy-octacore;
					roles = [
						./roles/corp.nix
					];
					inherit configFiles disko home-manager inputs nixpkgs nixvim sops-nix system timecard-bot;
				};
				"nocix-amd-legacy-sexcore" = import ./system.nix {
					configuration = ./host/nocix/amd-legacy-sexcore;
					roles = [
						./roles/nidus-sync.nix
						./roles/sovr.nix
					];
					inherit configFiles disko home-manager inputs nixpkgs nixvim sops-nix system timecard-bot;
				};
				"sync.nidus.cloud" = import ./system.nix {
					configuration = ./host/sync/configuration.nix;
					inherit configFiles disko home-manager inputs nixpkgs nixvim sops-nix system timecard-bot;
				};
				test-corp = nixpkgs.lib.nixosSystem {
					configuration = ./host/test-corp/configuration.nix;
					inherit configFiles disko home-manager inputs nixpkgs nixvim sops-nix system timecard-bot;
				};
			};
		};
}
