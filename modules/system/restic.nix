{ config, inputs, lib, pkgs, ... }:
{
	sops.secrets.restic-env = {
		format = "yaml";
		key = "backblaze";
		group = "root";
		mode = "0440";
		owner = "root";
		sopsFile = ../../secrets/restic.yaml;
	};
	sops.secrets.restic-password = {
		format = "yaml";
		key = "password";
		group = "root";
		mode = "0440";
		owner = "root";
		sopsFile = ../../secrets/restic.yaml;
	};
}
