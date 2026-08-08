{ pkgs, ... }: {
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    fastfetch
  ];

  programs.git = {
    enable = true;
  };
}

