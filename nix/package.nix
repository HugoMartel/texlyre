{
  lib,
  fetchFromGitHub,
  # stdenv,
  # fetchYarnDeps,
  # yarnConfigHook,
  # yarnBuildHook,
  buildNpmPackage,
  nodejs,
  biome
}:

let
  # Values taken from:
  # scripts/download-core-assets.cjs
  artifactsVersion = {
    "drawio-embed" = "v29.7.9";
    "texlyre-busytex" = "v1.1.1";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "texlyre";
  version = "0.8.0";

  # src = ../.;

  srcs = [
    # (../.)
    (fetchFromGitHub {
      owner = "TexLyre";
      repo = "texlyre";
      tag = "v0.8.0";
      hash = "sha256-aBGhTJS/UDcWOhzP4HtIQO5ZjNGXTj3oPLje65HIhe4=";
      name = "texlyre";
    })
    # Dependencies otherwise downloaded during the build
    (fetchFromGitHub {
      owner = "TexLyre";
      repo = "drawio-embed-mirror";
      tag = artifactsVersion.drawio-embed;
      hash = "sha256-mj+i+6n14Koo9TYaygrCgFg0OLfBZnnL6rE3PkJGa9w=";
      name = "drawio-embed";
    })
    (fetchTarball {
      url = "https://github.com/TeXlyre/texlyre-busytex/releases/download/assets-${artifactsVersion.texlyre-busytex}/busytex-assets.tar.gz";
      sha256 = "sha256-f/D/HS5Z4ZxDVFcT7U7zKALxYqbal9fJf5NDrrTSPNY=";
      name = "busytex";
    })
  ];

  sourceRoot = "texlyre";

  # Move the artifacts into their corresponding build folders
  postUnpack = ''
    mkdir -pv texlyre/public/core/drawio-embed
    mkdir -pv texlyre/public/core/busytex

    chmod -R u+r drawio-embed/
    chmod -R u+r busytex/

    cp -r drawio-embed/ texlyre/public/core/drawio-embed
    cp -r busytex/ texlyre/public/core/busytex
  '';

  patches = [
    ./patches/prevent-build-download.patch
  ];

  npmDepsHash = "sha256-davqKXgSwjPM0QQ/moo5sjh7e9wVXjH30SrFC4opmuQ=";

  nodejs = nodejs;

  nativeBuildInputs = [
    biome
  ];
  

  # Make sure to use a statically linked version of biome rather than
  # the default dynamically linked one after the `npm install` that will not work.
  postConfigure = ''
    # Replace the link to the dynamic binary with a statically linked one
    rm "node_modules/.bin/biome"
    # NOTE: this doesn't use the pinned version from package-lock.json
    # but as of writing this code, in nixpkgs 26.05 biome: 2.4.15,
    # and in package.json: ^2.4.11 and locked at 2.4.11 in package-lock.json
    ln --symbolic "${biome}/bin/biome" "node_modules/.bin/biome"

    # This alternative (not arch independent) doesn't seem to work, npm returns ENOTCACHED
    # ln --symbolic "node_modules/@biomejs/cli-linux-x64-musl/biome" "node_modules/.bin/biome"
  '';

  npmBuildScript = "build:prod";

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [ "--ignore-scripts" ];

  installPhase = ''
    mkdir -p $out
    cp -R dist/* $out
  '';

  meta = {
    description = "A in-browser LaTeX and Typst collaboration platform.";
    homepage = "https://texlyre.github.io";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
  };
})


# stdenv.mkDerivation (finalAttrs: {
#   pname = "texlyre";
#   version = "0.8.0";

#   src = ../.;

#   yarnOfflineCache = fetchYarnDeps {
#     yarnLock = finalAttrs.src + "/yarn.lock";
#     hash = "sha256-U6VxwVTfjlLF2BUNR+C9dusSwxSlbd+IbWjhC9KMqJs=";
#   };

#   # Make sure to use the statically linked version of biome rather than
#   # the default dynamically linked one after the `yarn install`.
#   # TODO: find a better system for systems other than linux
#   postConfigure = ''
#     # rm "./node_modules/.bin/biome"
#     # ln --symbolic "./node_modules/@biomejs/cli-linux-x64-musl/biome" "./node_modules/.bin/biome"
#     # rm "${finalAttrs.src}/node_modules/.bin/biome"
#     # ln --symbolic "${finalAttrs.src}/node_modules/@biomejs/cli-linux-x64-musl/biome" "${finalAttrs.src}/node_modules/.bin/biome"
#   '';

#   yarnBuildScript = "build:prod";
#   yarnBuildFlags = "";

#   nativeBuildInputs = [
#     yarnConfigHook
#     yarnBuildHook
#     nodejs
#   ];

#   installPhase = ''
#     mkdir -p $out
#     cp -R dist/* $out
#   '';

#   # NODE_OPTIONS = "--openssl-legacy-provider"; # TODO: check if needed
# })
