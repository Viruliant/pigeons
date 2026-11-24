{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  autoAddDriverRunpath,
  installShellFiles,
  writableTmpDirAsHomeHook,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pigeons";
  version = "X";
  # Points to the source code folder (nix/ -> repo root)
  src = ../.;
#   src = fetchFromGitHub {
#     owner = "Viruliant";
#     repo = "pigeons";
#     rev = version;
#     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
#   };

  # Original source, kept for reference:
  # src = fetchFromGitHub {
  #   owner = "rustonbsd";
  #   repo = "pigeons";
  #   tag = finalAttrs.version;
  #   hash = "sha256-0G2RZbxyxi96FpVPEamfcTrOgPxpFYHmyYg1kQfo7TQ=";
  # };

  cargoHash = "sha256-Xrt3+JPJFoNWgAPkf8qvy0CH+3hCnWyqrwd7Pk8kNCI=";

  # config_path_for_user_lands_in_that_users_home fails in the Nix sandbox
  doCheck = false;

  nativeBuildInputs = [
    autoAddDriverRunpath
    installShellFiles
  ];

  doInstallCheck = false;
  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  versionCheckProgram = "${placeholder "out"}/bin/pigeons";
  versionCheckProgramArg = "version";

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "ssh without ip";
    homepage = "https://github.com/rustonbsd/pigeons";
    license = lib.licenses.mit;
    mainProgram = "pigeons";
  };
})
