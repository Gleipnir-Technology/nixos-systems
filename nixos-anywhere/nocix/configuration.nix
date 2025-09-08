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
		pkgs.curl
		pkgs.dig
		pkgs.gitMinimal
	];
	networking = {
		defaultGateway = {
			address = "107.150.59.201";
			interface = "enp2s0";
		};
		defaultGateway6 = {
			address = "2604:4300:a:27e::1";
			interface = "enp2s0";
		};
		interfaces.enp2s0 = {
			ipv4.addresses = [{
				address = "107.150.59.202";
				prefixLength = 29;
			}];
			ipv6.addresses = [{
				address = "2604:4300:a:27e::2";
				prefixLength = 64;
			}];
		};
		nameservers = ["192.187.107.16"];
		search = ["nocix.net"];
	};
	services.openssh.enable = true;
	users.users.root.openssh.authorizedKeys.keys =
	[
		# change this to your ssh key
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos"
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHL1SpT3KR8XeXtH19muncYVrKxWzWdWtJYNTwoJGTm3 eliribble@Elis-Mac-mini.local"
	] ++ (args.extraPublicKeys or []); # this is used for unit-testing this module and can be removed if not needed
	system.stateVersion = "25.05";
}
