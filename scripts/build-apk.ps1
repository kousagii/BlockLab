param([ValidateSet('debug','release')][string]$Mode = 'debug', [switch]$SkipUnityExport)
. "$PSScriptRoot/environment.ps1"
& "$PSScriptRoot/check-environment.ps1"
if ($Mode -eq 'release' -and !(Test-Path (Join-Path $AppRoot 'android/key.properties'))) {
    throw 'Release key configuration is missing; use android/key.properties.example. Debug builds remain available.'
}
if (!$SkipUnityExport) { & "$PSScriptRoot/export-unity.ps1" }
if (!(Test-Path (Join-Path $AppRoot 'android/unityLibrary/build.gradle'))) { throw 'Unity export is missing.' }
Push-Location $AppRoot
try {
    Invoke-Checked $Flutter @('pub','get')
    Invoke-Checked (Join-Path (Split-Path $Flutter) 'dart.bat') @('run','build_runner','build')
    Invoke-Checked $Flutter @('analyze')
    Invoke-Checked $Flutter @('test')
    Invoke-Checked $Flutter @('build','apk',"--$Mode",'--target-platform','android-arm64')
    $apk = Join-Path $AppRoot "build/app/outputs/flutter-apk/app-$Mode.apk"
    if (!(Test-Path $apk)) { throw 'APK was not produced.' }
    Invoke-Checked (Join-Path $env:ANDROID_SDK_ROOT 'build-tools/35.0.0/apksigner.bat') @('verify','--print-certs',$apk)
    Invoke-Checked (Get-Command python).Source @((Join-Path $RepoRoot 'scripts/inspect-apk.py'),$apk,'--output',(Join-Path $LogRoot "apk-$Mode-inspection.json"))
    $variant = (Get-Culture).TextInfo.ToTitleCase($Mode)
    $manifestPath = Join-Path $AppRoot "build/app/intermediates/merged_manifests/$Mode/process${variant}Manifest/AndroidManifest.xml"
    if (!(Test-Path $manifestPath)) { throw "Merged manifest is missing: $manifestPath" }
    [xml]$manifest = Get-Content $manifestPath
    $namespace = 'http://schemas.android.com/apk/res/android'
    if ($manifest.manifest.application.GetAttribute('extractNativeLibs',$namespace) -ne 'true') {
        throw 'Host must extract native libraries for the Unity loader.'
    }
    foreach ($feature in $manifest.manifest.'uses-feature') {
        if ($feature.GetAttribute('name',$namespace) -in @('android.hardware.camera.ar','com.google.ar.core.depth')) {
            throw 'Core sandbox unexpectedly requires AR hardware.'
        }
    }
    Get-FileHash -LiteralPath $apk -Algorithm SHA256
} finally { Pop-Location }
