{ pkgs, ... }: {
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    fastfetch
    neovim
  ];

  programs.git = {
    enable = true;
  };
}

