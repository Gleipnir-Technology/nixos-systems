{ pkgs, lib, config, ... }:
with lib;
let
	src = pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "fieldseeker-sync";
		rev    = "5d19ceb020cf74327c966fabae51e0e1cdd7bd70";
		sha256 = "sha256-J2k3a960TT31eNp77wKUGJJZSaEYI9ENyVgxxY/RMls=";
  	};
in {
	options.myModules.fieldseeker-sync.enable = mkEnableOption "custom fieldseeker-sync configuration";

	config = mkIf config.myModules.fieldseeker-sync.enable {
		environment.systemPackages = [
			(pkgs.callPackage src { })
		];
	};
}
