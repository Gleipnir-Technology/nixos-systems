{ lib, ... }:
{
	networking = {
		defaultGateway = {
			address = "69.197.185.113";
			interface = "enp3s0";
		};
		defaultGateway6 = {
			address = "2604:4300:a:14c::";
			interface = "enp3s0";
		};
		domain = "gleipnir.technology";
		firewall = {
			allowedUDPPorts = [ 22 80 443 7000 16652 ];
			allowedTCPPorts = [ 22 80 443 7000 16652 ];
			enable = false;
			/*interfaces.enp3s0 = {
				allowedUDPPorts = [ 22 80 443 7000 16652 ];
				allowedTCPPorts = [ 22 80 443 7000 16652 ];
			};*/
		};
		hostName = "nocix-amd-legacy-quadcore";
		interfaces.enp3s0 = {
			ipv4.addresses = [{
				address = "69.197.185.114";
				prefixLength = 29;
			} {
				address = "69.197.185.115";
				prefixLength = 29;
			}];
			ipv6.addresses = [{
				address = "2604:4300:a:14c::2";
				prefixLength = 64;
			}];
		};
		nameservers = ["8.8.8.8"];
		networkmanager.enable = false;
		nftables.enable = true;
		useNetworkd = true;
		search = ["nocix.net"];
	};
}
