{ config, configFiles, lib, pkgs, ... }:

{
	services.openssh = {
		enable = true;
		# ports = [ 22 16652 ];
		listenAddresses = [{
			addr = "63.141.227.154";
			port = 22;
		} {
			addr = "63.141.227.154";
			port = 16652;
		} {
			addr = "63.141.227.155";
			port = 443;
		}];
	};

}
