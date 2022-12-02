{
  description = ''
    A nix flake that provides a home-manager module for modern unix commands.
  '';

  outputs = {self}: {
    homeManagerModule = import ./module.nix;
  };
}
