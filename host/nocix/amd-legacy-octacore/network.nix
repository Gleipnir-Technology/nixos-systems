{ lib, ... }: {
	networking = {
		defaultGateway = {
			address = "107.150.59.201";
			interface = "enp2s0";
		};
		defaultGateway6 = {
			address = "2604:4300:a:27e::1";
			interface = "enp2s0";
		};
		dhcpcd.enable = false;
		domain = "gleipnir.technology";
		firewall.enable = false;
		hostName = "nocix-amd-legacy-octacore";
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
		nftables.enable = true;
		search = ["nocix.net"];
		useNetworkd = true;
	};
}
