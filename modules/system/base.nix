{ config, configFiles, lib, pkgs, ... }:

{
	# Add my custom utilities
	_module.args.myutils = import ../../lib/myutils.nix { lib = lib; pkgs = pkgs; };

	boot.tmp.cleanOnBoot = true;
	environment.systemPackages = map lib.lowPrio [
		pkgs.curl
		pkgs.htop
		pkgs.git
		pkgs.sops
		pkgs.tig
	];
	i18n.defaultLocale = "en_US.UTF-8";
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	services.swapspace.enable = true;
	time.timeZone = "UTC";
	zramSwap.enable = true;

	# Copy the NixOS configuration file and link it from the resulting system
	# (/run/current-system/configuration.nix). This is useful in case you
	# accidentally delete configuration.nix.
	# system.copySystemConfiguration = true;

	# This option defines the first version of NixOS you have installed on this particular machine,
	# and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
	#
	# Most users should NEVER change this value after the initial install, for any reason,
	# even if you've upgraded your system to a new NixOS release.
	#
	# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
	# so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
	# to actually do that.
	#
	# This value being lower than the current NixOS release does NOT mean your system is
	# out of date, out of support, or vulnerable.
	#
	# Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
	# and migrated your data accordingly.
	#
	# For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
	system.stateVersion = "25.05";
}
