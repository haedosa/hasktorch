{
  description = "Hasktorch";

  inputs = {

    haedosa.url = "github:haedosa/flakes";
    nixpkgs.follows = "haedosa/nixpkgs-23-11";

    tokenizers.url = github:hasktorch/tokenizers/9d25f0ba303193e97f8b22b9c93cbc84725886c3;
    tokenizers.flake = false;

    typelevel-rewrite-rules.url = github:hasktorch/typelevel-rewrite-rules/17109219562cb679ee8fe0506f71863add4f23af;
    typelevel-rewrite-rules.flake = false;

    type-errors-pretty.url = github:hasktorch/type-errors-pretty/32d7abec6a21c42a5f960d7f4133d604e8be79ec;
    type-errors-pretty.flake = false;

    inline-c.url = github:fpco/inline-c/2d0fe9b2f0aa0e1aefc7bfed95a501e59486afb0;
    inline-c.flake = false;

  };


  outputs = inputs:

    let

      system = "x86_64-linux";

      inherit (inputs.nixpkgs) lib;

 sources = inputs;

      mk-overlay = import ./mk-overlay { inherit lib sources; };

      hasktorch-configs.cpu     = { profiling = true; cudaSupport = false; cudaMajorVersion = "invalid"; };
      hasktorch-configs.cuda-10 = { profiling = true; cudaSupport = true;  cudaMajorVersion = "10"; };
      hasktorch-configs.cuda-11 = { profiling = true; cudaSupport = true;  cudaMajorVersion = "11"; };

      overlays = __mapAttrs mk-overlay hasktorch-configs;

      overlay = self: super:
        ({
          hasktorchPkgs = __mapAttrs (_: super.extend) overlays;
        } // (mk-overlay "cuda-11" hasktorch-configs.cuda-11 self super));

      pkgs = import inputs.nixpkgs { inherit system; overlays = [ overlay ]; };

      ghc-name = "ghc948";

    in

      {

        inherit mk-overlay pkgs overlay overlays;

        packages.${system} = {

          default =
            let
              get-hasktorch = device: pkgs.hasktorchPkgs.${device}.haskell.packages.${ghc-name}.hasktorch;
              devices = __attrNames pkgs.hasktorchPkgs;
            in
              pkgs.linkFarm
                "hasktorch-all"
                (map
                  (device: {
                    name = "hasktorch-${device}";
                    path = get-hasktorch device; })
                  devices);

          libtorch-ffi = pkgs.haskellPackages.libtorch-ffi;
          hasktorch = pkgs.haskellPackages.hasktorch;

        } // __mapAttrs (device: pkgs: {
          inherit (pkgs.haskell.packages.${ghc-name}) hasktorch libtorch-ffi libtorch-ffi-helper;
        }) pkgs.hasktorchPkgs;


        devShell.${system} = pkgs.haskell.packages.${ghc-name}.shellFor {
          packages = p: with p; [
            hasktorch
            libtorch-ffi
            libtorch-ffi-helper
            codegen
            examples
          ];
          buildInputs =
            (with pkgs.haskellPackages;
              [ haskell-language-server
                # threadscope
              ]) ++
            (with pkgs;
              [
                ghcid.bin
                cabal-install
              ]) ++
            (with pkgs.libtorch-libs;
              [
                c10
                torch
                torch_cpu
              ]);
        };

      };

}
