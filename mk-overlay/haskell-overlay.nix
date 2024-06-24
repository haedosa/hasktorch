{ lib, haskell, linkFarm, hasktorch-config, libtorch, libtorch-libs, stdenv, sources, setup-num-cores }:

let

  overlay = lib.composeManyExtensions [
    overlay-base
    overlay-setup-num-cores
    overlay-flag
  ];

  hlib = haskell.lib.compose;

  inherit (hasktorch-config) cudaSupport cudaMajorVersion;

  inherit (stdenv.hostPlatform) isDarwin;

  mk-flag-opt = flag: pred: if pred then "-f${flag}" else "-f-${flag}";

  overlay-base =
    hself: hsuper:
    (__mapAttrs
      (pname: path: hself.callCabal2nix pname path {})
      {
        tokenizers-haskell      = "${sources.tokenizers}/bindings/haskell/tokenizers-haskell";
        typelevel-rewrite-rules = sources.typelevel-rewrite-rules;
        type-errors-pretty      = sources.type-errors-pretty;
        codegen                 = ../codegen;
        libtorch-ffi-helper     = ../libtorch-ffi-helper;
        hasktorch               = ../hasktorch;
        examples                = ../examples;
        experimental            = ../experimental;
      })
    //
    {
      libtorch-ffi =
        hlib.dontHaddock (hself.callCabal2nixWithOptions "libtorch-ffi" ../libtorch-ffi
          (__concatStringsSep " " [
            (mk-flag-opt "rocm" false)
            (mk-flag-opt "cuda" cudaSupport)
            (mk-flag-opt "gcc" (!cudaSupport && isDarwin))
          ])
          {
            inherit (libtorch-libs) torch c10 torch_cpu;
            ${if cudaSupport then "torch_cuda" else null} = libtorch-libs.torch_cuda;
          });
    };

  overlay-setup-num-cores = hself: hsuper: {
    codegen      = setup-num-cores hsuper.codegen;
    libtorch-ffi = setup-num-cores (hlib.dontHaddock hsuper.libtorch-ffi);
    hasktorch    = setup-num-cores hsuper.hasktorch;
  };

  overlay-flag = hself: hsuper: {
    tokenizers   = hlib.appendConfigureFlag "--extra-lib-dirs=${hself.tokenizers-haskell}/lib" hsuper.tokenizers;
    libtorch-ffi =
      hlib.appendConfigureFlags
        [
          "--extra-include-dirs=${libtorch.dev}/include/torch/csrc/api/include"
          "--extra-lib-dirs=${libtorch.out}/lib"
        ]
        (hlib.dontHaddock hsuper.libtorch-ffi);
  };

in overlay
