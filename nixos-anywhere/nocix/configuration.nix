{
	modulesPath,
	lib,
	pkgs,
	...
} @ args:
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
		(modulesPath + "/profiles/qemu-guest.nix")
		./disk-config.nix
	];
	boot.loader.grub = {
		# no need to set devices, disko will add all devices that have a EF02 partition to the list already
		# devices = [ ];
		efiSupport = true;
		efiInstallAsRemovable = true;
	};
	environment.systemPackages = map lib.lowPrio [
		pkgs.dig
	];
	networking = {
		defaultGateway = {
			address = "107.150.59.201";
			interface = "enp2s0";
		};
		interfaces.enp2s0 = {
			ipv4.addresses = [{
				address = "107.150.59.202";
				prefixLength = 29;
			}];
		};
		nameservers = ["192.187.107.16"];
		search = ["nocix.net"];
	};
}
