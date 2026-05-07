{ lib, ... }:
{
	networking = {
		defaultGateway = {
			address = "107.150.42.1";
			interface = "enp2s0";
		};
		defaultGateway6 = {
			address = "2604:4300:a:30::1";
			interface = "enp2s0";
		};
		domain = "gleipnir.technology";
		firewall = {
			allowedUDPPorts = [ 22 80 443 7000 16652 ];
			allowedTCPPorts = [ 22 80 443 7000 16652 ];
			enable = false;
			/*interfaces.enp2s0 = {
				allowedUDPPorts = [ 22 80 443 7000 16652 ];
				allowedTCPPorts = [ 22 80 443 7000 16652 ];
			};*/
		};
		hostName = "nocix-amd-legacy-quadcore-292465";
		interfaces.enp2s0 = {
			ipv4.addresses = [{
				address = "107.150.42.2";
				prefixLength = 29;
			}];
			ipv6.addresses = [{
				address = "2604:4300:a:30::2";
				prefixLength = 64;
			}];
		};
		nameservers = ["8.8.8.8"];
		networkmanager.enable = false;
		#nftables.enable = true;
		search = ["nocix.net"];
		useNetworkd = true;
	};
}
