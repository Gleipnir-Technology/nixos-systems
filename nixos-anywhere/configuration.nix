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

	myModules = {
		# Disable standard cloud-init, use nixos-anywhere special cloud-init instead
		cloud-init.enable = false;
		do-agent.enable = true;
	};
}
