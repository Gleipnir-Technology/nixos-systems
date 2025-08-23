{ config, lib, pkgs, ... }: {
	imports = [
		./hardware-configuration.nix
	];
	myModules.caddy.enable = true;
	myModules.fieldseeker-sync.enable = true;
	networking = {
		firewall = {
			enable = true;
			interfaces.ens3 = {
				allowedUDPPorts = [ 22 80 443 ];
				allowedTCPPorts = [ 22 80 443 ];
			};
			trustedInterfaces = [
				"ens4"
				"lo"
			];
		};
		networkmanager.enable = false;
		nftables = {
			enable = true;
		};
		useNetworkd = true;
	};
}
