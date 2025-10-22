{ config, lib, pkgs, ... }: {
	myModules.caddy.enable = true;
	myModules.frps = {
		domains = [
			"audiobooks.theribbles.org"
			"auth.theribbles.org"
			"carddav.theribbles.org"
			"chores.theribbles.org"
			"collabora.theribbles.org"
			"docs.theribbles.org"
			"files.theribbles.org"
			"home-assistant.theribbles.org"
			"movies.theribbles.org"
			"notes.theribbles.org"
			"passwords.theribbles.org"
			"pdf.theribbles.org"
			"photos.theribbles.org"
			"plex.theribbles.org"
			"source.theribbles.org"
			"todo.theribbles.org"
			"tv.theribbles.org"
		];
		enable = true;
	};
}
