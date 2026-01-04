{
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
			url = "github:nix-community/home-manager/release-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nidus-sync = {
			type = "github";
			owner = "Gleipnir-Technology";
			repo = "nidus-sync";
			rev = "637decea113ba1bbed7b373244f5989e00626f38";
		};
		nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
		nixvim = {
			url = "github:nix-community/nixvim/nixos-25.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix.url = "github:Mic92/sops-nix";
		timecard-bot.url = "github:Gleipnir-Technology/timecard-bot?rev=8c81b6683f97aa2712323836e629adf102be58ac";
	};

	outputs =
		inputs@{
			disko,
			home-manager,
			nixpkgs,
			nixos-facter-modules,
			nixvim,
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
					./digitalocean
					disko.nixosModules.disko
					{ disko.devices.disk.disk1.device = "/dev/vda"; }
					home-manager.nixosModules.home-manager {
						home-manager.extraSpecialArgs = { inherit configFiles; };
						home-manager.sharedModules = [
							nixvim.homeManagerModules.nixvim
							../modules/home/nixvim.nix
						];
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
			nixosConfigurations.nocix = nixpkgs.lib.nixosSystem {
				modules = [
					../modules
					../users
					./nocix
					disko.nixosModules.disko
					home-manager.nixosModules.home-manager {
						home-manager.extraSpecialArgs = { inherit configFiles; };
						home-manager.sharedModules = [
							nixvim.homeManagerModules.nixvim
							../modules/home/nixvim.nix
						];
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
					}
					inputs.authentik-nix.nixosModules.default
					sops-nix.nixosModules.sops {
						sops = {
							age.generateKey = true;
							age.keyFile = "/var/libs/sops-nix/key.txt";
							age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
							defaultSopsFile = ./secrets/secrets.yaml;
						};
					}
				];
				specialArgs = {
					inherit configFiles inputs;
				};
				system = "${system}";
			};
		};
}
