{ pkgs, lib, config, ... }:
with lib;
let
	src = pkgs.fetchFromGitHub {
		owner  = "Gleipnir-Technology";
		repo   = "fieldseeker-sync";
		rev    = "ff56a904cc9212434a1f8025cafafe59f8b48b4f";
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
