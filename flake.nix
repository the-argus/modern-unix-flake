{
  description = ''
    A nix flake that provides a home-manager module for modern unix commands.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-22.05";
  };

  outputs = {
    self,
    nixpkgs,
  } @ inputs: {
    homeManagerModule = import ./module.nix;
  };
}
