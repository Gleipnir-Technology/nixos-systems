{ config, configFiles, lib, pkgs, ... }:

{
	# Add my custom utilities
	_module.args.myutils = import ../../lib/myutils.nix { lib = lib; pkgs = pkgs; };

	boot.tmp.cleanOnBoot = true;
	environment.systemPackages = map lib.lowPrio [
		pkgs.binutils
		pkgs.cloud-init
		pkgs.curl
		pkgs.dig
		pkgs.htop
		pkgs.ghostty.terminfo
		pkgs.git
		pkgs.git-lfs
		pkgs.jq
		pkgs.restic
		pkgs.sops
		pkgs.tig
		pkgs.watchexec
	];
	i18n.defaultLocale = "en_US.UTF-8";
	networking.useNetworkd = true;
	nix.settings = {
		download-buffer-size = 524288000;
		experimental-features = [ "nix-command" "flakes" ];
		trusted-users = [ "eliribble" ];
	};
	programs.mosh.enable = true;
	security.pam.loginLimits = [{
		domain = "*";
		type = "soft";
		item = "nofile";
		value = "8192";
	}];
	services.swapspace.enable = true;
	systemd.network = {
		enable = true;
		wait-online = {
			anyInterface = true;
			timeout = 10;
		};
	};
	time.timeZone = "UTC";
	zramSwap.enable = true;
}
