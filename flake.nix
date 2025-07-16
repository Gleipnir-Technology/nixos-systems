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
	};

	outputs = { self, home-manager, nixpkgs, nixvim }:
		let
			allowed-unfree-packages = [
				"corefonts"
			];
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
				corp = nixpkgs.lib.nixosSystem {
					modules = [
						./host/corp/configuration.nix
						./modules
					];
					pkgs = import nixpkgs {
						config = {
							allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) allowed-unfree-packages;
						};
						system = "${system}";
					};
					specialArgs = {
						inherit configFiles;
					};
					system = "${system}";
				};
			};
		};
}
