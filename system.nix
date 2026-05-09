{ configuration, inputs, nixpkgs, roles ? [], system}:
let
	allowed-unfree-packages = [
		"corefonts"
		"google-chrome"
		"mongodb"
	];
	
	configFiles = nixpkgs.legacyPackages.${system}.stdenv.mkDerivation {
		name = "config-files";
		src = ./configs;
		installPhase = ''
			mkdir -p $out
			cp -r * $out/
		'';
	};
	
	pkgs = import nixpkgs {
		inherit system;
		config = {
			allowUnfreePredicate = pkg: 
				builtins.elem (nixpkgs.lib.getName pkg) allowed-unfree-packages;
		};
	};
in
nixpkgs.lib.nixosSystem {
	inherit system pkgs;
	
	specialArgs = {
		inherit inputs configFiles;
	};
	
	modules = [
		configuration
		inputs.authentik-nix.nixosModules.default
		inputs.disko.nixosModules.disko
		inputs.home-manager.nixosModules.home-manager
		{
			home-manager.extraSpecialArgs = { inherit configFiles inputs; };
			home-manager.sharedModules = [
				inputs.nixvim.homeModules.nixvim
				./modules/home/nixvim.nix
			];
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
		}
		inputs.sops-nix.nixosModules.sops
		{
			sops = {
				age.generateKey = true;
				age.keyFile = "/var/lib/sops-nix/key.txt";
				age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
				defaultSopsFile = ./secrets/secrets.yaml;
			};
		}
		./modules
		./users
	] ++ roles;
}
