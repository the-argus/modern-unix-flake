{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkIf;
  optional = bool: str:
    if bool
    then str
    else "";
  cfg = config.programs.modernUnix;
  defaultTrueBool = description:
    mkOption {
      type = types.bool;
      default = true;
      inherit description;
    };
in {
  options.programs.modernUnix = {
    enable = mkEnableOption ''
      Enable all the modern unix commands provided in this flake.
    '';

    excludePackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        ranger
        broot
        exa # lsd is better
        glances # gtop is better
        choose # i will forget to use this one
        cheat # i dont use these
        jq
        httpie
        curlie
        xh
        dogdns
      ];
      description = ''
        Commands to exclude, by package.
      '';
    };

    rangerZoxideIntegration = mkEnableOption "Install ranger-zoxide.";

    createAliases = defaultTrueBool ''
      Whether or not to alias the old equivalents of these modern commands
      to the the new commands. Basically means "default to modern unix."
      Will only alias backwards-compatible (or mostly backwards-compatible)
      commands, unless aggressiveAliasing is true.
    '';

    aggressiveAliasing = mkEnableOption ''
      Whether or not to alias similar but incompatible commands.
    '';

    initZoxide = defaultTrueBool "Add init command for zoxide in modernunixrc.";
    initMcfly = defaultTrueBool "Add init command for mcfly in modernunixrc.";

    initExtra = mkOption {
      type = types.lines;
      default = '''';
      description = ''
        Additional zsh script to by imported when evaluating the 
        init command.'';
    };
  };
  config = let
    using = pkg: !(lib.lists.any (value: value == pkg) cfg.excludePackages);
    shellInit = builtins.toFile "modernunixrc" ''
      ${
        optional cfg.createAliases ''
          alias htop="gtop"
          alias ping="gping"
          alias man="tldr"
          alias back="z -"
          alias cd="z"
          alias df="duf"
          alias top="procs"
          alias diff="delta"
          function ls () {
            lsd $@ --group-dirs=first
          }
          alias cat="bat"
          ${
            (optional cfg.aggressiveAliasing ''
              alias find="fd"
              alias grep="rg"
              alias cut="choose"
              alias sed="sd"
              alias df="duf"
            '')
          }
        ''
      }

      ${
        optional ((using pkgs.mcfly) && cfg.initMcfly) "eval \"$(mcfly init zsh)\""
      }
      ${
        optional ((using pkgs.zoxide) && cfg.initZoxide) "eval \"$(zoxide init zsh)\""
      }

      ${cfg.initExtra}
    '';
    modernUnix =
      pkgs.writeShellScriptBin
      "modern-unix"
      "${pkgs.coreutils-full}/bin/cat ${shellInit}";

    # putting it in this file should allow the user to override
    # this desktop association by creating their own markdown.desktop
    mdrWithDesktop = pkgs.mdr.overrideAttrs (oa: {
      postInstall = let
        desktopEntry = builtins.toFile "markdown.desktop" ''
          [Desktop Entry]
          Name=mdr
          GenericName=Markdown Viewer
          Comment=CLI Markdown Renderer
          Exec=mdr %f
          Terminal=true
          Type=Application
          NoDisplay=true
          MimeType=text/markdown
        '';
      in ''
        mkdir -p $out/share/applications
        cp ${desktopEntry} $out/share/applications/markdown.desktop
      '';
    });
  in
    mkIf cfg.enable {
      home.packages = with pkgs;
        lib.lists.subtractLists
        cfg.excludePackages
        [
          # navigation
          zoxide
          ranger
          broot

          # search
          fzf
          mcfly # search through shell history
          ripgrep
          silver-searcher # ag
          fd

          # directory info
          lsd
          exa
          duf

          # file info
          delta
          du-dust
          bat

          # processes
          gtop
          procs
          # bottom # (needs packaging)
          glances

          # info/help
          tldr
          cheat

          # fancy...
          gping
          mdrWithDesktop # excellent markdown renderer

          # util
          choose # cut/awk alternative
          jq # sed for json data
          sd # simpler but less featured sed
          hyperfine # cli benchmarking tool

          # networking
          httpie
          curlie
          xh
          dogdns

          # package for this module
          modernUnix
        ];

      xdg.mimeApps = {
        defaultApplications."text/markdown" = ["markdown.desktop"];
      };

      home.file = {
        ".config/ranger/plugins/zoxide" = {
          source = pkgs.fetchgit {
            url = "https://github.com/jchook/ranger-zoxide";
            sha256 = "10i44dqz4c27g6sq54bhyx7pycnmmy1b52di2y3v9dm40yw8cl0w";
            rev = "363df97af34c96ea873c5b13b035413f56b12ead";
          };
          recursive = true;
        };
      };
    };
}
