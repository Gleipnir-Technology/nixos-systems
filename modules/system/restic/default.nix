{ pkgs, lib, config, ... }:
with lib;
{
	# Disable the stable channel version of restic and use our
	# local copy of the unstable version so that we get access to stdin-from-command
	disabledModules = [ "services/backup/restic.nix" ];
	imports = [
		./restic.nix
	];
	config = {
		sops.secrets.restic-env = {
			format = "yaml";
			key = "backblaze-${config.myModules.restic.role}";
			group = "root";
			mode = "0440";
			owner = "root";
			sopsFile = ../../../secrets/restic.yaml;
		};
		sops.secrets.restic-password = {
			format = "yaml";
			key = "password-${config.myModules.restic.role}";
			group = "root";
			mode = "0440";
			owner = "root";
			sopsFile = ../../../secrets/restic.yaml;
		};
	};
	options.myModules.restic.role = mkOption {
		description = "The role which picks the key to use";
		type = types.str;
	};
}
