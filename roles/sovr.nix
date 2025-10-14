{ config, lib, pkgs, ... }: {
	myModules.caddy.enable = true;
	myModules.frps = {
		enable = true;
		subdomains = [
			"audiobooks"
			"auth"
			"carddav"
			"chores"
			"collabora"
			"docs"
			"files"
			"home-assistant"
			"movies"
			"notes"
			"passwords"
			"pdf"
			"photos"
			"plex"
			"source"
			"todo"
			"tv"
		];
	};
}
