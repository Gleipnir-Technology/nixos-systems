{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	services.cloud-init = {
		enable = true;
		network.enable = true;
	};
}
