{ pkgs, lib, config, ... }:
with lib;
let
	timecardBotSrc = pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "timecard-bot";
		rev    = "00b2850655295513c1e99a519d1d59c3b9847122";
		sha256 = "1f78jm3jgzwzc69q1h9nplmcbz5hb9l74phyhzkbfjb99n3vrf1q";
	};
	timecardBotFlake = (import timecardBotSrc);
	timecardBotPackage = timecardBotFlake.packages.${pkgs.system}.default;
in
{
	options.myModules.timecardbot.enable = mkEnableOption "custom timecardbot configuration";

	config = mkIf config.myModules.timecardbot.enable {
		#environment.systemPackages = with pkgs; [
			#timecardBotPackage
		#];
	};
}
