param()
. "$PSScriptRoot/environment.ps1"
if (!(Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python 3.11+ is required for the APK native-library inspector.' }
foreach ($path in @($UnityEditor, $Flutter, (Join-Path $UnityAndroid 'NDK/source.properties'),
    (Join-Path $env:JAVA_HOME 'bin/java.exe'), (Join-Path $env:ANDROID_SDK_ROOT 'platforms/android-36/android.jar'),
    (Join-Path $env:ANDROID_SDK_ROOT 'build-tools/35.0.0/aapt2.exe'),
    (Join-Path $env:ANDROID_SDK_ROOT 'ndk/28.2.13676358/source.properties'),
    (Join-Path $env:ANDROID_SDK_ROOT 'cmake/3.22.1/bin/cmake.exe'))) {
    if (!(Test-Path -LiteralPath $path)) { throw "Missing build prerequisite: $path" }
}
Invoke-Checked $Flutter @('--version')
Invoke-Checked (Join-Path $env:JAVA_HOME 'bin/java.exe') @('-version')
Write-LocalProperties
Write-Host "Unity editor: $UnityEditor"
Write-Host "Android SDK: $env:ANDROID_SDK_ROOT"
Write-Host 'Environment ready. Unity licensing is checked by the export process.'
