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
						home-manager.nixosModules.home-manager
						{
							home-manager.useGlobalPkgs = true;
							home-manager.useUserPackages = true;
							home-manager.users.eliribble = import ./home.nix;
						}
						./host/corp/configuration.nix
						./modules
						sops-nix.nixosModules.sops {
							sops = {
								age.generateKey = true;
								age.keyFile = "/var/libs/sops-nix/key.txt";
								age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
								defaultSopsFile = ./secrets/secrets.yaml;
								secrets.matrix = {
									format = "yaml";
									group = "matrix-synapse";
									key = "";
									owner = "matrix-synapse";
									restartUnits = [ "matrix-synapse.service" ];
									sopsFile = ./host/corp/secrets/matrix.yaml;
								};
								secrets.vikunja = {
									format = "yaml";
									group = "vikunja";
									key = "";
									owner = "vikunja";
									path = "/etc/vikunja/config.yaml";
									restartUnits = [ "vikunja.service" ];
									sopsFile = ./host/corp/secrets/vikunja.yaml;
								};
							};
						}
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
