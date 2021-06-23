{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/b1da480910cfd8870cdc0896b3a422c513be05c1.tar.gz") { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.azure-cli
    pkgs.terraform_1_0
  ];
}
