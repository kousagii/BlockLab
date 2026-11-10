$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$AppRoot = Join-Path $RepoRoot 'flutter_app'
$UnityVersion = ((Get-Content (Join-Path $RepoRoot 'unity/ProjectSettings/ProjectVersion.txt') | Select-Object -First 1) -split ': ')[1]
if ($env:UNITY_EDITOR) { $UnityEditor = $env:UNITY_EDITOR }
else { $UnityEditor = Join-Path ${env:ProgramFiles} "Unity/Hub/Editor/$UnityVersion/Editor/Unity.exe" }
$UnityAndroid = Join-Path (Split-Path $UnityEditor) 'Data/PlaybackEngines/AndroidPlayer'
if ($env:FLUTTER_ROOT) { $Flutter = Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat' }
elseif (Test-Path (Join-Path $RepoRoot '.tools/flutter/bin/flutter.bat')) { $Flutter = Join-Path $RepoRoot '.tools/flutter/bin/flutter.bat' }
else {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if (!$command) { throw 'Flutter SDK missing. Run scripts/bootstrap-tools.ps1 or set FLUTTER_ROOT.' }
    $Flutter = $command.Source
}
if (!$env:JAVA_HOME -or !(Test-Path (Join-Path $env:JAVA_HOME 'bin/java.exe'))) {
    $bundledJdk = Get-ChildItem (Join-Path $RepoRoot '.tools/jdk17') -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bundledJdk) { $env:JAVA_HOME = $bundledJdk.FullName }
    else { throw 'JDK 17 missing. Set JAVA_HOME or run scripts/bootstrap-tools.ps1.' }
}
if (!$env:ANDROID_SDK_ROOT) {
    if (Test-Path (Join-Path $RepoRoot '.tools/android-sdk')) { $env:ANDROID_SDK_ROOT = Join-Path $RepoRoot '.tools/android-sdk' }
    else { $env:ANDROID_SDK_ROOT = Join-Path $UnityAndroid 'SDK' }
}
$env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
$env:PUB_CACHE = Join-Path $RepoRoot '.tools/pub-cache'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
$env:PATH = (Join-Path $env:JAVA_HOME 'bin') + ';' + $env:PATH
$LogRoot = Join-Path $RepoRoot 'logs'
New-Item -ItemType Directory -Force $LogRoot | Out-Null
function Invoke-Checked {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}
function Write-LocalProperties {
    $flutterRoot = Split-Path (Split-Path $Flutter)
    $values = @(
        ('sdk.dir=' + $env:ANDROID_SDK_ROOT.Replace('\','/'))
        ('flutter.sdk=' + $flutterRoot.Replace('\','/'))
        ('unity.ndk=' + (Join-Path $UnityAndroid 'NDK').Replace('\','/'))
    )
    [IO.File]::WriteAllLines((Join-Path $AppRoot 'android/local.properties'), $values)
}
