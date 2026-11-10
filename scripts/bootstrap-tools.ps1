param()
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $repo '.tools'
$logs = Join-Path $repo 'logs'
New-Item -ItemType Directory -Force $tools,$logs | Out-Null
if (!(Test-Path (Join-Path $tools 'flutter/bin/flutter.bat'))) {
    $releases = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    $release = $releases.releases | Where-Object version -eq '3.41.4' | Select-Object -First 1
    if (!$release) { throw 'Flutter 3.41.4 was not found in the official archive.' }
    $zip = Join-Path $tools 'flutter.zip'
    Invoke-WebRequest ('https://storage.googleapis.com/flutter_infra_release/releases/' + $release.archive) -OutFile $zip
    if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $release.sha256) { throw 'Flutter checksum mismatch.' }
    Expand-Archive -LiteralPath $zip -DestinationPath $tools
}
if (!(Get-ChildItem (Join-Path $tools 'jdk17') -Directory -ErrorAction SilentlyContinue)) {
    $assets = Invoke-RestMethod 'https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
    $package = $assets[0].binary.package
    $zip = Join-Path $tools 'jdk17.zip'
    Invoke-WebRequest $package.link -OutFile $zip
    if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $package.checksum) { throw 'JDK checksum mismatch.' }
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tools 'jdk17')
}
. "$PSScriptRoot/environment.ps1"
$source = Join-Path $UnityAndroid 'SDK'
if (!(Test-Path $source)) { throw 'Install Android Build Support with SDK/NDK/OpenJDK for Unity 2022.3.62f3 in Unity Hub.' }
if ($env:ANDROID_SDK_ROOT -eq $source) { $env:ANDROID_SDK_ROOT = Join-Path $tools 'android-sdk' }
$dest = $env:ANDROID_SDK_ROOT
$env:ANDROID_HOME = $dest
# Copy only the SDK components used by this project. No mirroring or deletion.
foreach ($component in @('cmdline-tools','platform-tools','platforms/android-36','build-tools/34.0.0')) {
    $from = Join-Path $source $component
    if (!(Test-Path $from)) {
        if ($component -eq 'platforms/android-36') { continue }
        throw "Missing Unity SDK component: $from"
    }
    & robocopy $from (Join-Path $dest $component) /E /MT:16 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "Could not copy $component" }
}
$manager = Join-Path $dest 'cmdline-tools/6.0/bin/sdkmanager.bat'
# Use Unity's known SDK manager. Newer wrappers change package argument syntax.
1..20 | ForEach-Object {'y'} | & $manager "--sdk_root=$dest" --licenses *> (Join-Path $logs 'android-sdk-licenses.log')
if ($LASTEXITCODE -ne 0) { throw 'SDK license setup failed; see logs/android-sdk-licenses.log.' }
& $manager "--sdk_root=$dest" 'platforms;android-36' 'build-tools;35.0.0' 'ndk;28.2.13676358' 'cmake;3.22.1'
if ($LASTEXITCODE -ne 0) { throw 'Android build-tool installation failed.' }
& "$PSScriptRoot/check-environment.ps1"
