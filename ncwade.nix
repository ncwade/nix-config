{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports = [
    ./yubikey-gpg.nix
    (import "${home-manager}/nixos")
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config = {
    chromium = {
      enableWideVine = true;
    };
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  environment.variables.EDITOR = "nvim";
  fonts.fonts = with pkgs; [
    jetbrains-mono
  ];
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  users.users.ncwade = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDK6YOsxAa22T8i7oSI1cSnRpCXdlb7SO0DnVg8bz4fOqxNCqFXrrREAHVteanIxvBtPFPHekL9EsXhDZkKMXWITQIuXk0Hoi01V/5h1NbmIGNO1JrlXOUQsdVKyt97H3MSYhpxRT3fC1wRQUukfhaYP/lFnST81mqSzlPQ2MYvZzfFRIqQ2ImULunXEIk7bG4JemKGs1C6zmxUUwBs1QQwAMESnVZLTdU/fSsz+b2KNnwAKn9sskRN8Q+3Y/ckWvpULxVtg4Vr5WgA52b27F7E08CdkX1ZWgC7kGc2fFtVz6gYlTce3w1dH/EMZi9ZsqP/zLGf0EkyPERhofi4EfSkmj/osGzsz4HpCREARpUR+fOy/M11nTOsTcJyUB4vc/r0Nn+G0juvRaC+jRs3fNMw6whE2JJJFgNfkHdwP8GeHmAPE9uAELrQvrx+3wxuJl6u+7UdEoFs4oAix11J/LoXKYlr4UP9g9/tHevmBroiHdOVhFeGYo1vP/SOS+TnHY4xuA5fMxTvpSASUJS6vnxSwP9EyCztGnI3ljvQKOdqsjRCtpvek2W3EwflbYQ18ItqJfbfgG8o0sHdNPj7RRLQMusvnEKsi0H5FLOu+ajdOfDsYE+q64ASr1li1JgFRHKX6vda0PT6dsJIgu6PJ7XK5dA8AHJmPyCX+n1CfWDpJQ== cardno:14 832 816"
    ];
    isNormalUser = true;
    shell = pkgs.fish;
    group = "users";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  home-manager.users.ncwade = {
    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
      # TODO: This is broken for ungoogled chromium.
      # extensions = [
      #   { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
      #   { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1password
      #   { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # privacy badger
      # ];
    };

    programs.neovim = {
      enable = true;
      plugins = with pkgs; [
      ];

      extraConfig = builtins.readFile ./config/init.vim;
    };
    programs.tmux = {
      enable = true;
      terminal = "xterm-256color";

      plugins = with pkgs.tmuxPlugins; [
        {
         plugin = dracula;
         extraConfig = ''
            set -g @dracula-show-battery false
            set -g @dracula-show-powerline true
            set -g @dracula-refresh-rate 20
            set -g @dracula-show-left-icon 🚀
          '';
        }
      ];
      extraConfig = ''
        unbind '"'
        unbind %
        unbind M-j
        unbind M-k
        unbind M-h
        unbind M-l

        # Window Management
        bind | split-window -h
        bind - split-window -v
        bind-key -n C-S-Up resize-pane -U 10
        bind-key -n C-S-Down resize-pane -D 10
        bind-key -n C-S-Left resize-pane -L 10
        bind-key -n C-S-Right resize-pane -R 10

        # Movement
        bind k set-option -g status
        bind j set-option -g status
        bind h previous-window
        bind l next-window
        bind-key -n M-j select-pane -D
        bind-key -n M-k select-pane -U
        bind-key -n M-h select-pane -L
        bind-key -n M-l select-pane -R

        # Utilities
        bind r source-file ~/.config/tmux/tmux.conf
      '';
    };
    programs.gpg = {
      enable = true;
    };
    programs.git = {
      enable = true;
      userName = "Nick Wade";
      userEmail = "me@ncwade.com";
      signing = {
        key = "8A892A4DCAB96A68";
        signByDefault = true;
      };
      extraConfig = {
        github.user = "ncwade";
        push.default = "simple";
        init.defaultBranch = "main";
        url."git@github-gdcorp:/gdcorp-infosec".insteadOf = "https://github.com/gdcorp-infosec";
        url."git@github.com:".insteadOf = "https://github.com/";
      };
    };
    programs.fish = {
      enable = true;
      shellAliases = {
        pbcopy = "xclip";
        pbpaste = "xclip -o";
        nix-grub-clean = "sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch";
      };

      interactiveShellInit = builtins.readFile ./config/config.fish;

      plugins = [
        {
          name = "theme-bobthefish";
          src = pkgs.fetchFromGitHub {
            owner = "oh-my-fish";
            repo = "theme-bobthefish";
            rev = "332f23abd7a095d5b2c024a061af7b890a4f0c20";
            sha256 = "0nhhc0d5z9k0srpalg7dv6zrls0qsw29bqp9vaajipcz53j7x6lf";
          };
        }
        {
          name = "z";
          src = pkgs.fetchFromGitHub {
              owner = "jethrokuan";
              repo = "z";
              rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
              sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
          };
        }
        {
          name = "fish-fzf";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "6b592e4140168820f5df9dd28b0a93e409e0d0c3";
            sha256 = "1xzh5jwgilnk5rh7wywmzw1s084b2pilh0hvkfm5kyl37hmh0y3n";
          };
        }
      ];
    };

    programs.kitty = {
      enable = true;
      extraConfig = builtins.readFile ./config/kitty;
    };

    xdg.configFile."kdeglobals".source = ./config/kdeglobals;
    xdg.configFile."direnv/direnvrc".source = ./config/direnvrc;

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          identityFile = "~/.ssh/ncwade.pub";
          identitiesOnly = true;
        };
        "github-gdcorp" = {
          hostname = "github.com";
          identityFile = "~/.ssh/nwade-godaddy.pub";
          identitiesOnly = true;
        };
      };
    };

    home.sessionVariables = {
      CONFIGURE_OPTS="--with-openssl=$(nix eval --raw nixpkgs.openssl.dev.outPath)";
      CPPFLAGS="-I$(nix eval --raw nixpkgs.zlib.dev.outPath)/include -I$(nix eval --raw nixpkgs.libffi.dev.outPath)/include -I$(nix eval --raw nixpkgs.openssl.dev.outPath)/include -I$(nix eval --raw nixpkgs.readline.dev.outPath)/include -I$(nix eval --raw nixpkgs.ncurses.dev.outPath)/include -I$(nix eval --raw nixpkgs.expat.dev.outPath)/include -I$(nix eval --raw nixpkgs.sqlite.dev.outPath)/include -I$(nix eval --raw nixpkgs.bzip2.dev.outPath)/include";
      LDFLAGS="-L$(nix eval --raw nixpkgs.zlib.out)/lib -L$(nix eval --raw nixpkgs.libffi.out)/lib -L$(nix eval --raw nixpkgs.openssl.out)/lib -L$(nix eval --raw nixpkgs.readline.outPath)/lib -L$(nix eval --raw nixpkgs.ncurses.out)/lib -L$(nix eval --raw nixpkgs.expat.outPath)/lib -L$(nix eval --raw nixpkgs.sqlite.out)/lib -L$(nix eval --raw nixpkgs.bzip2.out)/lib";
    };
    programs.go.enable = true;
    home.packages = [
      pkgs.barrier
      pkgs.kitty
      pkgs.fzf
      pkgs.bat
      pkgs.htop
      pkgs.jq
      pkgs.xclip
      pkgs.fd
      pkgs.python3
      pkgs.ripgrep
      pkgs.kubectl
      pkgs.poetry
      pkgs.python3Packages.pipx
      pkgs.gnumake
      pkgs.binutils
      pkgs.zlib.dev
      pkgs.libffi.dev
      pkgs.openssl.dev
      pkgs.readline.dev
      pkgs.ncurses.dev
      pkgs.expat.dev
      pkgs.sqlite.dev
      pkgs.bzip2.dev
      pkgs.xz
      pkgs.gcc
      pkgs.nodejs
      pkgs.docker-compose
      pkgs.libcap
      pkgs.pre-commit
      pkgs.direnv
      pkgs.gh
      pkgs.pyright
    ];
  };
}

