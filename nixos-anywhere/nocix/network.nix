{ lib, ... }:
{
	networking = {
		defaultGateway = {
			address = "63.141.227.153";
			interface = "enp3s0";
		};
		defaultGateway6 = {
			address = "2604:4300:a:88::1";
			interface = "enp3s0";
		};
		interfaces.enp3s0 = {
			ipv4.addresses = [{
				address = "63.141.227.154";
				prefixLength = 29;
			}];
			ipv6.addresses = [{
				address = "2604:4300:a:88::2";
				prefixLength = 64;
			}];
		};
		nameservers = ["8.8.8.8"];
		search = ["nocix.net"];
	};
}
