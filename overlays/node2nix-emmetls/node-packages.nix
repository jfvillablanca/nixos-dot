# This file has been generated by node2nix 1.11.1. Do not edit!

{nodeEnv, fetchurl, fetchgit, nix-gitignore, stdenv, lib, globalBuildInputs ? []}:

let
  sources = {
    "@emmetio/abbreviation-2.2.2" = {
      name = "_at_emmetio_slash_abbreviation";
      packageName = "@emmetio/abbreviation";
      version = "2.2.2";
      src = fetchurl {
        url = "https://registry.npmjs.org/@emmetio/abbreviation/-/abbreviation-2.2.2.tgz";
        sha512 = "TtE/dBnkTCct8+LntkqVrwqQao6EnPAs1YN3cUgxOxTaBlesBCY37ROUAVZrRlG64GNnVShdl/b70RfAI3w5lw==";
      };
    };
    "@emmetio/css-abbreviation-2.1.4" = {
      name = "_at_emmetio_slash_css-abbreviation";
      packageName = "@emmetio/css-abbreviation";
      version = "2.1.4";
      src = fetchurl {
        url = "https://registry.npmjs.org/@emmetio/css-abbreviation/-/css-abbreviation-2.1.4.tgz";
        sha512 = "qk9L60Y+uRtM5CPbB0y+QNl/1XKE09mSO+AhhSauIfr2YOx/ta3NJw2d8RtCFxgzHeRqFRr8jgyzThbu+MZ4Uw==";
      };
    };
    "@emmetio/scanner-1.0.0" = {
      name = "_at_emmetio_slash_scanner";
      packageName = "@emmetio/scanner";
      version = "1.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/@emmetio/scanner/-/scanner-1.0.0.tgz";
        sha512 = "8HqW8EVqjnCmWXVpqAOZf+EGESdkR27odcMMMGefgKXtar00SoYNSryGv//TELI4T3QFsECo78p+0lmalk/CFA==";
      };
    };
    "@types/node-17.0.0" = {
      name = "_at_types_slash_node";
      packageName = "@types/node";
      version = "17.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/@types/node/-/node-17.0.0.tgz";
        sha512 = "eMhwJXc931Ihh4tkU+Y7GiLzT/y/DBNpNtr4yU9O2w3SYBsr9NaOPhQlLKRmoWtI54uNwuo0IOUFQjVOTZYRvw==";
      };
    };
    "emmet-2.3.5" = {
      name = "emmet";
      packageName = "emmet";
      version = "2.3.5";
      src = fetchurl {
        url = "https://registry.npmjs.org/emmet/-/emmet-2.3.5.tgz";
        sha512 = "LcWfTamJnXIdMfLvJEC5Ld3hY5/KHXgv1L1bp6I7eEvB0ZhacHZ1kX0BYovJ8FroEsreLcq7n7kZhRMsf6jkXQ==";
      };
    };
    "typescript-4.5.4" = {
      name = "typescript";
      packageName = "typescript";
      version = "4.5.4";
      src = fetchurl {
        url = "https://registry.npmjs.org/typescript/-/typescript-4.5.4.tgz";
        sha512 = "VgYs2A2QIRuGphtzFV7aQJduJ2gyfTljngLzjpfW9FoYZF6xuw1W0vW9ghCKLfcWrCFxK81CSGRAvS1pn4fIUg==";
      };
    };
    "vscode-jsonrpc-6.0.0" = {
      name = "vscode-jsonrpc";
      packageName = "vscode-jsonrpc";
      version = "6.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-jsonrpc/-/vscode-jsonrpc-6.0.0.tgz";
        sha512 = "wnJA4BnEjOSyFMvjZdpiOwhSq9uDoK8e/kpRJDTaMYzwlkrhG1fwDIZI94CLsLzlCK5cIbMMtFlJlfR57Lavmg==";
      };
    };
    "vscode-languageserver-7.0.0" = {
      name = "vscode-languageserver";
      packageName = "vscode-languageserver";
      version = "7.0.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver/-/vscode-languageserver-7.0.0.tgz";
        sha512 = "60HTx5ID+fLRcgdHfmz0LDZAXYEV68fzwG0JWwEPBode9NuMYTIxuYXPg4ngO8i8+Ou0lM7y6GzaYWbiDL0drw==";
      };
    };
    "vscode-languageserver-protocol-3.16.0" = {
      name = "vscode-languageserver-protocol";
      packageName = "vscode-languageserver-protocol";
      version = "3.16.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-protocol/-/vscode-languageserver-protocol-3.16.0.tgz";
        sha512 = "sdeUoAawceQdgIfTI+sdcwkiK2KU+2cbEYA0agzM2uqaUy2UpnnGHtWTHVEtS0ES4zHU0eMFRGN+oQgDxlD66A==";
      };
    };
    "vscode-languageserver-textdocument-1.0.3" = {
      name = "vscode-languageserver-textdocument";
      packageName = "vscode-languageserver-textdocument";
      version = "1.0.3";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-textdocument/-/vscode-languageserver-textdocument-1.0.3.tgz";
        sha512 = "ynEGytvgTb6HVSUwPJIAZgiHQmPCx8bZ8w5um5Lz+q5DjP0Zj8wTFhQpyg8xaMvefDytw2+HH5yzqS+FhsR28A==";
      };
    };
    "vscode-languageserver-types-3.16.0" = {
      name = "vscode-languageserver-types";
      packageName = "vscode-languageserver-types";
      version = "3.16.0";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-types/-/vscode-languageserver-types-3.16.0.tgz";
        sha512 = "k8luDIWJWyenLc5ToFQQMaSrqCHiLwyKPHKPQZ5zz21vM+vIVUSvsRpcbiECH4WR88K2XZqc4ScRcZ7nk/jbeA==";
      };
    };
  };
  args = {
    name = "emmet-ls";
    packageName = "emmet-ls";
    version = "0.3.1";
    src = ./.;
    dependencies = [
      sources."@emmetio/abbreviation-2.2.2"
      sources."@emmetio/css-abbreviation-2.1.4"
      sources."@emmetio/scanner-1.0.0"
      sources."@types/node-17.0.0"
      sources."emmet-2.3.5"
      sources."typescript-4.5.4"
      sources."vscode-jsonrpc-6.0.0"
      sources."vscode-languageserver-7.0.0"
      sources."vscode-languageserver-protocol-3.16.0"
      sources."vscode-languageserver-textdocument-1.0.3"
      sources."vscode-languageserver-types-3.16.0"
    ];
    buildInputs = globalBuildInputs;
    meta = {
      description = "emmet support by LSP";
      license = "MIT";
    };
    production = true;
    bypassCache = true;
    reconstructLock = false;
  };
in
{
  args = args;
  sources = sources;
  tarball = nodeEnv.buildNodeSourceDist args;
  package = nodeEnv.buildNodePackage args;
  shell = nodeEnv.buildNodeShell args;
  nodeDependencies = nodeEnv.buildNodeDependencies (lib.overrideExisting args {
    src = stdenv.mkDerivation {
      name = args.name + "-package-json";
      src = nix-gitignore.gitignoreSourcePure [
        "*"
        "!package.json"
        "!package-lock.json"
      ] args.src;
      dontBuild = true;
      installPhase = "mkdir -p $out; cp -r ./* $out;";
    };
  });
}
