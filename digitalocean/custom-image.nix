let
  ## Pin the latest NixOS stable (nixos-25.05) release:
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.05.tar.gz";
    sha256 = "sha256:0q96nxw7jg9l9zlpa3wkma5xzmgkdnnajapwhgb2fk2ll224rgs1";
  };

  ## Import nixpkgs:
  pkgs = import nixpkgs { };

  ## Prepare the NixOS configuration:
  config = {
    imports = [
      "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
    ];
  };
in
(pkgs.nixos config).digitalOceanImage
