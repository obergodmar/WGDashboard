{
  buildNpmPackage,
  lib,
  makeWrapper,
  python3,
  src,
  stdenvNoCC,
}:

let
  version = "4.3.4-dev";

  adminFrontend = buildNpmPackage {
    pname = "wgdashboard-admin-frontend";
    inherit version;
    src = "${src}/src/static/app";
    npmDepsHash = "sha256-tJAduHjXxoypVkOnD8j7TiYixtkweQxAd6nd8ErczHE=";
    npmFlags = [ "--legacy-peer-deps" ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ../dist/WGDashboardAdmin/. $out/
      runHook postInstall
    '';
  };

  clientFrontend = buildNpmPackage {
    pname = "wgdashboard-client-frontend";
    inherit version;
    src = "${src}/src/static/client";
    npmDepsHash = "sha256-eR9wt0COJogFOGKSfI1s0yCeRWPASFhNL7VHV8X4B8s=";
    npmFlags = [ "--legacy-peer-deps" ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ../dist/WGDashboardClient/. $out/
      runHook postInstall
    '';
  };

  python = python3.withPackages (
    ps: with ps; [
      bcrypt
      flask
      flask-cors
      gunicorn
      icmplib
      packaging
      psutil
      psycopg
      pydantic
      pymysql
      pyotp
      python-jose
      requests
      sqlalchemy
      sqlalchemy-utils
      tzlocal
    ]
  );
in
stdenvNoCC.mkDerivation {
  pname = "wgdashboard";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    PYTHONPATH=src ${python}/bin/python -m unittest discover -s tests -v
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/wgdashboard/static/dist/WGDashboardAdmin
    mkdir -p $out/share/wgdashboard/static/dist/WGDashboardClient
    cp -r src/. $out/share/wgdashboard
    rm -rf $out/share/wgdashboard/static/dist/WGDashboardAdmin
    rm -rf $out/share/wgdashboard/static/dist/WGDashboardClient
    cp -r ${adminFrontend}/. $out/share/wgdashboard/static/dist/WGDashboardAdmin/
    cp -r ${clientFrontend}/. $out/share/wgdashboard/static/dist/WGDashboardClient/

    makeWrapper ${python}/bin/gunicorn $out/bin/wgdashboard \
      --set PYTHONPATH $out/share/wgdashboard \
      --set WGDASHBOARD_ASSET_PATH $out/share/wgdashboard \
      --add-flags "--config ${./gunicorn.conf.py}"
    makeWrapper ${python}/bin/python $out/bin/wgdashboard-initialize \
      --add-flags ${./initialize.py}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    stateDir=$(mktemp -d)
    printf 'correct horse battery staple\n' > "$stateDir/password"
    printf '[Peers]\npeer_global_dns = 1.1.1.1,1.0.0.1\n' > "$stateDir/settings.ini"
    $out/bin/wgdashboard-initialize \
      --configuration-path "$stateDir" \
      --settings-file "$stateDir/settings.ini" \
      --password-file "$stateDir/password" \
      --listen-address 127.0.0.1 \
      --port 10086 \
      --wireguard-path "$stateDir/wireguard" \
      --amneziawg-path "$stateDir/amneziawg"
    $out/bin/wgdashboard-initialize \
      --configuration-path "$stateDir" \
      --settings-file "$stateDir/settings.ini" \
      --listen-address 127.0.0.1 \
      --port 10086 \
      --wireguard-path "$stateDir/wireguard" \
      --amneziawg-path "$stateDir/amneziawg"
    grep --quiet '^peer_global_dns = 1.1.1.1,1.0.0.1$' "$stateDir/wg-dashboard.ini"
    CONFIGURATION_PATH="$stateDir" \
      WGDASHBOARD_AUTOSTART_INTERFACES=false \
      WGDASHBOARD_BIND=127.0.0.1:10086 \
      $out/bin/wgdashboard --check-config

    runHook postInstallCheck
  '';

  meta = {
    description = "Web dashboard for WireGuard and AmneziaWG";
    homepage = "https://github.com/WGDashboard/WGDashboard";
    license = lib.licenses.mit;
    mainProgram = "wgdashboard";
    platforms = lib.platforms.linux;
  };
}
