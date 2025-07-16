{ config, lib, pkgs, ... }:
with lib;
let
	fqdn = "matrix.gleipnir.technology";
	baseUrl = "https://${fqdn}";
	clientConfig."m.homeserver".base_url = baseUrl;
	serverConfig."m.server" = "${fqdn}:443";
	mkWellKnown = data: ''
		default_type application/json;
		add_header Access-Control-Allow-Origin *;
		return 200 '${builtins.toJSON data}';
	'';
in {
	options.myModules.synapse.enable = mkEnableOption "custom synapse configuration";

	config = mkIf config.myModules.synapse.enable {
		services.nginx = {
			virtualHosts."chat.gleipnir.technology" = {
				enableACME = true;
				forceSSL = true;
				# Host element web client at the root
				root = pkgs.element-web.override {
					conf = {
						default_server_config = clientConfig;
					};
				};
			};
			virtualHosts."corp.gleipnir.technology" = {
				enableACME = true;
				forceSSL = true;
				# This section is not needed if the server_name of matrix-synapse is equal to
				# the domain (i.e. example.org from @foo:example.org) and the federation port
				# is 8448.
				# Further reference can be found in the docs about delegation under
				# https://element-hq.github.io/synapse/latest/delegate.html
				locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
				# This is usually needed for homeserver discovery (from e.g. other Matrix clients).
				# Further reference can be found in the upstream docs at
				# https://spec.matrix.org/latest/client-server-api/#getwell-knownmatrixclient
				locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
			};
			virtualHosts."matrix.gleipnir.technology" = {
				enableACME = true;
				forceSSL = true;
				# It's also possible to do a redirect here or something else, this vhost is not
				# needed for Matrix. It's recommended though to *not put* element
				# here, see also the section about Element.
				locations."/".extraConfig = ''
					return 404;
				'';
				# Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
				# *must not* be used here.
				locations."/_matrix" = {
					extraConfig = ''
						proxy_set_header X-Forwarded-Proto $scheme;
						proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
						include /etc/nginx/proxy.conf;
					'';
					proxyPass = "http://[::1]:8008";
				};

				# Forward requests for e.g. SSO and password-resets.
				locations."/_synapse/client" = {
					extraConfig = ''
						proxy_set_header X-Forwarded-Proto $scheme;
						proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
						include /etc/nginx/proxy.conf;
					'';
					proxyPass = "http://[::1]:8008";
				};
			};
			virtualHosts."matrix-bot.gleipnir.technology" = {
				enableACME = true;
				forceSSL = true;
				locations."/" = {
					extraConfig = ''
						proxy_set_header X-Forwarded-Proto $scheme;
						proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
						include /etc/nginx/proxy.conf;
					'';
					proxyPass = "http://[::1]:10050";
				};
			};
		};

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
	};
}
