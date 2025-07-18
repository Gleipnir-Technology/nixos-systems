{ pkgs, lib, config, ... }:
with lib;
let
	clientConfig."m.homeserver".base_url = baseUrl;
in {
	options.myModules.element-web.enable = mkEnableOption "custom element-web configuration";

	config = mkIf config.myModules.element-web.enable {
		environment.systemPackages = with pkgs; [
			element-web
		];
		services.caddy.virtualHosts."chat.gleipnir.technology".extraConfig = ''
			file_server
			root * ${pkgs.element-web}
		'';
	};
}
