{ config, configFiles, inputs, lib, pkgs, ... }:
with lib;

let
	cfg = config.myModules.pi;
	group = "root";
	user = "root";
in {
	options.myModules.pi = {
		domainName = mkOption {
			example = "staging-pi.nidus.cloud";
			type = types.str;
		};
		enable = mkEnableOption "custom pi configuration";
	};

	config = mkIf config.myModules.pi.enable {
		environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
			pkgs.nodejs_24
			pi
		];
		sops.secrets."pi-env" = {
			format = "dotenv";
			group = "${group}";
			mode = "0400";
			owner = "${user}";
			#restartUnits = ["${nidusNameWebserver}.service"];
			sopsFile = ../../secrets/pi.env;
		};
	};
	/* notes on other stuff I did

	I'm installing pi-semaphore and pi-tmux with:

	```shell
	pi install git:github.com/offline-ant/pi-semaphore
	pi install git:github.com/offline-ant/pi-tmux
	```
	*/

}
