{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    hostName = "corp";
    defaultGateway = "159.89.144.1";
    defaultGateway6 = {
      address = "2604:a880:2:d1::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    domain = "gleipnir.technology";
    firewall.enable = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="159.89.154.99"; prefixLength=20; }
          { address="10.46.0.5"; prefixLength=16; }
        ];
        ipv4.routes = [ { address = "159.89.144.1"; prefixLength = 32; } ];
        ipv6.addresses = [
          { address="2604:a880:2:d1::7f9a:6001"; prefixLength=64; }
          { address="fe80::d4a8:45ff:fe46:cd11"; prefixLength=64; }
        ];
        ipv6.routes = [ { address = "2604:a880:2:d1::1"; prefixLength = 128; } ];
      };
      eth1 = {
        ipv4.addresses = [
          { address="10.120.0.2"; prefixLength=20; }
        ];
        ipv6.addresses = [
          { address="fe80::4ac:1fff:fe36:cb24"; prefixLength=64; }
        ];
      };
    };
    nameservers = [
      "67.207.67.3"
      "67.207.67.2"
      "67.207.67.3"
      "67.207.67.2"
      "67.207.67.3"
      "67.207.67.2"
    ];
    usePredictableInterfaceNames = lib.mkForce false;
  };
  services.udev.extraRules = ''
    ATTR{address}=="d6:a8:45:46:cd:11", NAME="eth0"
    ATTR{address}=="06:ac:1f:36:cb:24", NAME="eth1"
  '';
}
