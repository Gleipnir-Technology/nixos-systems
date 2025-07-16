{
	programs.nixvim = {
		colorschemes.catppuccin.enable = true;
		enable = true;
		opts = {
			number = true;
		};
		plugins.lsp = {
			enable = true;
			servers = {
				# golang
				gopls = {
					enable = true;
				};
			};
		};
	};
}
