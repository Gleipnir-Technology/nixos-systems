{ pkgs, lib, config, ... }:
with lib;
{
	# Disable the stable channel version of restic and use our
	# local copy of the unstable version so that we get access to stdin-from-command
	disabledModules = [ "services/backup/restic.nix" ];
	imports = [
		./restic.nix
	];
}
