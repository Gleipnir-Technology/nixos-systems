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
		pkgs.gitMinimal
	];

	myModules.tmux.enable = true;

	services.openssh.enable = true;

	system.stateVersion = "25.05";

	users.users.root.openssh.authorizedKeys.keys =
	[
		"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos"
	] ++ (args.extraPublicKeys or []); # this is used for unit-testing this module and can be removed if not needed

}
