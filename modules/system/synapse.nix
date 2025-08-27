{ config, lib, pkgs, ... }:
with lib;
let
	fqdn = "matrix.gleipnir.technology";
	baseUrl = "https://${fqdn}";
	clientConfig."m.homeserver".base_url = baseUrl;
	serverConfig."m.server" = "${fqdn}:443";
in {
	options.myModules.synapse.enable = mkEnableOption "custom synapse configuration";

	config = mkIf config.myModules.synapse.enable {
		services.caddy.virtualHosts."corp.gleipnir.technology".extraConfig = ''
			# This is usually needed for homeserver discovery (from e.g. other Matrix clients).
			# Further reference can be found in the upstream docs at
			# https://spec.matrix.org/latest/client-server-api/#getwell-knownmatrixclient
			# This section is not needed if the server_name of matrix-synapse is equal to
			# the domain (i.e. example.org from @foo:example.org) and the federation port
			# is 8448.
			# Further reference can be found in the docs about delegation under
			# https://element-hq.github.io/synapse/latest/delegate.html
			#Headers & Well-known for Matrix & Element Call
			header /.well-known/matrix/* Content-Type application/json
			header /.well-known/matrix/* Access-Control-Allow-Origin *
			respond /.well-known/matrix/server `{"m.server": "matrix.gleipnir.technology:443"}`
			respond /.well-known/matrix/client `{"m.homeserver": {"base_url": "https://matrix.gleipnir.technology"}, "org.matrix.msc4143.rtc_foci": [{"type": "livekit", "livekit_service_url": "https://livekit.gleipnir.technology"}]}`
		'';
		services.caddy.virtualHosts."matrix.gleipnir.technology".extraConfig = ''
			reverse_proxy http://[::1]:8008
		'';

		services.matrix-synapse = {
			enable = true;
			extras = ["oidc"];
			extraConfigFiles = [
				"/run/secrets/matrix"
			];
			log.root.level = "WARNING";
			settings = {
				listeners = [
					{ port = 8008;
						bind_addresses = [ "::1" ];
						type = "http";
						tls = false;
						x_forwarded = true;
						resources = [ {
							names = [ "client" "federation" ];
							compress = true;
						} ];
					}
				];
				# The public base URL value must match the `base_url` value set in `clientConfig` above.
				# The default value here is based on `server_name`, so if your `server_name` is different
				# from the value of `fqdn` above, you will likely run into some mismatched domain names
				# in client applications.
				public_baseurl = baseUrl;
				server_name = config.networking.domain;
			};
		};
		sops.secrets.matrix = {
			format = "yaml";
			group = "matrix-synapse";
			key = "";
			owner = "matrix-synapse";
			restartUnits = [ "matrix-synapse.service" ];
			sopsFile = ../../secrets/matrix.yaml;
		};
	};
}
