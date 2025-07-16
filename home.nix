{ config, pkgs, ... }:

{
	home.file.".config/nvim/after/ftplugin/html.vim".source = ./home/eliribble/config/nvim/after/ftplugin/html.vim;
	home.file.".config/nvim/after/ftplugin/go.vim".source = ./home/eliribble/config/nvim/after/ftplugin/go.vim;
	home.file.".config/tmux/tmux.conf".source = ./home/eliribble/config/tmux/tmux.conf;
	home.homeDirectory = "/home/eliribble";
	home.stateVersion = "24.11";
	home.username = "eliribble";
}
