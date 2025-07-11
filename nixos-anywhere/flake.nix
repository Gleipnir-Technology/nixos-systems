{
	inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
	inputs.disko.url = "github:nix-community/disko";
	inputs.disko.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

	outputs =
		{
			nixpkgs,
			disko,
			nixos-facter-modules,
			...
		}:
		{
			# tested with 2GB/2CPU droplet, 1GB droplets do not have enough RAM for kexec
			nixosConfigurations.digitalocean = nixpkgs.lib.nixosSystem {
				system = "x86_64-linux";
				modules = [
					./digitalocean.nix
					disko.nixosModules.disko
					{ disko.devices.disk.disk1.device = "/dev/vda"; }
					./configuration.nix
				];
			};
		};
}
