{ config, lib, pkgs, ... }: {
	disabledModules = [ 
		"services/web-apps/onlyoffice.nix"
	];
	imports = [
		./hardware-configuration.nix
		./networking.nix # generated at runtime by nixos-infect
	];

	boot.tmp.cleanOnBoot = true;
	environment.systemPackages = with pkgs; [
		age
		element-web
		fish
		git
		htop
		neovim
		podman
		postgresql
		redis
		slirp4netns
		tmux
		wget
	];
	i18n.defaultLocale = "en_US.UTF-8";
	myModules = {
		onlyoffice.enable = true;
		seafile.enable = true;
		synapse.enable = true;
		timecardbot.enable = true;
	};
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	programs.neovim.enable = true;
	programs.neovim.defaultEditor = true;
	security.acme = {
		acceptTerms = true;
		defaults.email = "eli@gleipnir.technology";
	};
	security.sudo.wheelNeedsPassword = false;
	# The Digital Ocean droplet agent
	services.do-agent.enable = true;
	services.nginx = {
		# This adds the 'recommendedProxyConfig' without actually adding it since if I do add it,
		# it'll include $nginx-recommended-proxy_set_headers-headers.conf at the http level, outside
		# a server block, which breaks everything.
		appendHttpConfig = ''
			proxy_redirect					off;
			proxy_connect_timeout	 60s;
			proxy_send_timeout			60s;
			proxy_read_timeout			60s;
			proxy_http_version			1.1;
			# don't let clients close the keep-alive connection to upstream. See the nginx blog for details:
			# https://www.nginx.com/blog/avoiding-top-10-nginx-configuration-mistakes/#no-keepalives
			proxy_set_header				"Connection" "";
		'';
		enable = true;
		recommendedGzipSettings = true;
		recommendedProxySettings = false;
		virtualHosts."auth.gleipnir.technology" = {
			addSSL = true;
			enableACME = true;
			locations."/" = {
				extraConfig = ''
					proxy_set_header Upgrade $http_upgrade;
					proxy_set_header Connection $connection_upgrade;
					proxy_set_header X-Forwarded-Proto $scheme;
					proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
					include /etc/nginx/proxy.conf;
				'';
				proxyPass = "http://127.0.0.1:10000";
			};
			root = "/var/www/auth";
		};
		virtualHosts."static.gleipnir.technology" = {
			addSSL = true;
			enableACME = true;
			locations."/" = {
				index = "index.html";
			};
			root = "/var/www/static";
		};
		virtualHosts."todo.gleipnir.technology" = {
			addSSL = true;
			enableACME = true;
			locations."/" = {
				extraConfig = ''
					proxy_set_header Upgrade $http_upgrade;
					proxy_set_header Connection $connection_upgrade;
					proxy_set_header X-Forwarded-Proto $scheme;
					proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
					include /etc/nginx/proxy.conf;
				'';
				proxyPass = "http://127.0.0.1:10010";
			};
			root = "/var/www/todo";
		};
	};
	services.openssh.enable = true;
	services.redis = {
		servers."" = {
			bind = "127.0.0.1";
			enable = true;
		};
	};
	services.swapspace.enable = true;
	services.vikunja = {
		enable = true;
		frontendHostname = "todo.gleipnir.technology";
		frontendScheme = "https";
	};
	time.timeZone = "America/Phoenix";

	users.groups.vikunja = {};
	users.users.deploy = {
		extraGroups = [ "deploy" ];
		isNormalUser = true;
	};
	users.users.eliribble = {
		extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
		initialHashedPassword = "$y$j9T$XYOMZR8RZEiTnpaF8lsxv1$H7YbWDpzbnYXTLN0ZMhvtKOlSMy64P7C/RdLBaeaNf/";
		isNormalUser = true;
		openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos"];
	};
	users.users.root.openssh.authorizedKeys.keys = [
		''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBvhtF6nRWlA6PVs71Eek7p0p2PxTd3P6ZEGFV2t75MB eliribble@nixos'' 
	];
	users.users.vikunja = {
		group = "vikunja";
		isNormalUser = false;
		isSystemUser = true;
	};
	virtualisation.podman.enable = true;
	zramSwap.enable = true;

	# Copy the NixOS configuration file and link it from the resulting system
	# (/run/current-system/configuration.nix). This is useful in case you
	# accidentally delete configuration.nix.
	# system.copySystemConfiguration = true;

	# This option defines the first version of NixOS you have installed on this particular machine,
	# and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
	#
	# Most users should NEVER change this value after the initial install, for any reason,
	# even if you've upgraded your system to a new NixOS release.
	#
	# This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
	# so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
	# to actually do that.
	#
	# This value being lower than the current NixOS release does NOT mean your system is
	# out of date, out of support, or vulnerable.
	#
	# Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
	# and migrated your data accordingly.
	#
	# For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
	system.stateVersion = "23.11";
}
