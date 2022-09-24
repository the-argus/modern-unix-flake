{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkIf;
  cfg = config.programs.modernUnix;
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

    createAliases = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether or not to alias the old equivalents of these modern commands
        to the the new commands. Basically means "default to modern unix."
        Will only alias backwards-compatible (or mostly backwards-compatible)
        commands, unless aggressiveAliasing is true.
      '';
    };

    aggressiveAliasing = mkEnableOption ''
      Whether or not to alias similar but incompatible commands.
    '';

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
      alias htop="gtop"
      alias ping="gping"
      alias man="tldr"
      alias back="z -"
      alias cd="z"
      alias df="duf"
      alias top="procs"
      alias diff="delta"
      function ls () {
        lsd --group-dirs=first $@
      }
      alias cat="bat"
      ${
        if cfg.aggressiveAliasing
        then ''
          alias find="fd"
          alias grep="rg"
          alias cut="choose"
          alias sed="sd"
          alias df="duf"
        ''
        else ""
      }

      ${
        if using pkgs.mcfly
        then "eval \"$(mcfly init zsh)\""
        else ""
      }
      ${
        if using pkgs.zoxide
        then "eval \"$(zoxide init zsh)\""
        else ""
      }

      ${cfg.initExtra}
    '';
    modernUnix =
      pkgs.writeShellScriptBin
      "modern-unix"
      "${pkgs.coreutils-full}/bin/cat ${shellInit}";
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
