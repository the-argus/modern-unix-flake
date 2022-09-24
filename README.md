# modern-unix-flake
A home manager module that provides commands from [ibraheemdev/modern-unix.](github.com/ibraheemdev/modern-unix)

# requirements
Zsh shell. Could add partial bash support if anyone wants it.

# usage
After importing the flake into HM, add the following into your HM config:
```nix
{
  modernUnix.enable = true;
  programs.zsh.initExtra = ''
      # hook aliases into your shell. Technically optional,
      # but it's the best part.
      eval "$(modernunix)"
  '';
}
```

# to-do
- Add [bottom](https://github.com/ClementTsang/bottom) (requires packaging, maybe
PR to nixpkgs.

# goals
This is meant to provide a bunch of good defaults. It does not allow for much
customization because doing this yourself is fairly easy. It's basically just
defaults for the ``programs.zsh`` module supplied by home manager.
