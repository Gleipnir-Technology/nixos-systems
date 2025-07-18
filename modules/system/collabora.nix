{ config, lib, pkgs, ... }:

with lib;

{
        options.myModules.collabora.enable = mkEnableOption "custom collabora configuration";

        config = mkIf config.myModules.collabora.enable {
                virtualisation.oci-containers.containers.collabora = {
                        image = "collabora/code";
                        ports = [ "127.0.0.1:10010:9980" ];
                        environment = {
                                domain = "collabora.gleipnir.technology";
                                extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
                        };
                        extraOptions = [
                                "--cap-add"
                                "MKNOD"
                      ];
                };

}
