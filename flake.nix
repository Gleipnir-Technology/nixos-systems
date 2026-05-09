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
		fieldseeker-sync = {
			type = "github";
			owner = "Gleipnir-Technology";
			repo = "fieldseeker-sync";
			rev = "e250e0abbb35f6d64851305d3b59c4ed1d968bc8";
		};
		home-manager = {
			url = "github:nix-community/home-manager/release-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		llm-agents.url = "github:numtide/llm-agents.nix";
		nidus-sync = {
			type = "github";
			owner = "Gleipnir-Technology";
			repo = "nidus-sync";
			rev = "4bd62b3567b94c9c0ba7b13f2547a0a4d38979d4";
		};
		nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
		nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
		nixvim = {
			url = "github:nix-community/nixvim/nixos-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix.url = "github:Mic92/sops-nix";
		timecard-bot.url = "github:Gleipnir-Technology/timecard-bot?rev=8c81b6683f97aa2712323836e629adf102be58ac";
	};

	outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, ... }: {
		nixosConfigurations = {
			"nocix-amd-legacy-octacore" = import ./system.nix {
				inherit inputs;
				configuration = ./host/nocix/amd-legacy-octacore;
				nixpkgs = nixpkgs;
				roles = [
					./roles/corp.nix
				];
				system = "x86_64-linux";
			};
			"nocix-amd-legacy-quadcore" = import ./system.nix {
				inherit inputs;
				configuration = ./host/nocix/amd-legacy-quadcore;
				nixpkgs = nixpkgs;
				roles = [
					./roles/nidus-sync.nix
				];
				system = "x86_64-linux";
			};
			"nocix-amd-legacy-quadcore-292465" = import ./system.nix {
				inherit inputs;
				configuration = ./host/nocix/amd-legacy-quadcore-292465;
				nixpkgs = nixpkgs-unstable;
				roles = [ ./roles/llm.nix ];
				system = "x86_64-linux";
			};
			"nocix-amd-legacy-sexcore" = import ./system.nix {
				inherit inputs;
				configuration = ./host/nocix/amd-legacy-sexcore;
				nixpkgs = nixpkgs;
				roles = [
					./roles/nidus-marketing.nix
					./roles/nidus-sync.nix
					./roles/sovr.nix
				];
				system = "x86_64-linux";
			};
		};
	};
}
