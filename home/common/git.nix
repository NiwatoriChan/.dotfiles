# Git configuration via home-manager
{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        # TODO: Fill in your name and email
        name = "niwatorichan";
        email = "charloslivro2@gmail.com";  # <-- Set your email here
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
