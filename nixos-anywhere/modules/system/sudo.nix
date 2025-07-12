{ config, lib, pkgs, configFiles, ... }:

with lib;

{
	security.sudo.wheelNeedsPassword = false;
}
