{ config, configPath, lib, pkgs, ... }:

with lib;

{
	environment.systemPackages = [ pkgs.fish ];
}
