param([switch]$VerifyOnly)
. "$PSScriptRoot/environment.ps1"
if (!(Test-Path -LiteralPath $UnityEditor)) { throw "Unity editor missing: $UnityEditor" }
Write-LocalProperties
$exportPath = [IO.Path]::GetFullPath((Join-Path $AppRoot 'android/unityLibrary'))
$expected = [IO.Path]::GetFullPath((Join-Path $RepoRoot 'flutter_app/android/unityLibrary'))
if ($exportPath -ne $expected) { throw 'Unsafe Unity export destination.' }
$method = if ($VerifyOnly) { 'BlockLabBuild.VerifySceneRoundTrip' } else { 'BlockLabBuild.ExportAndroid' }
$log = Join-Path $LogRoot $(if ($VerifyOnly) {'unity-verification.log'} else {'unity-export.log'})
$arguments = @('-batchmode','-nographics','-quit','-buildTarget','Android','-projectPath',
    (Join-Path $RepoRoot 'unity'),'-executeMethod',$method,'-exportPath',$exportPath,'-logFile',$log)
# Wait for Unity itself. Start-Process -Wait also waits for long-lived licensing children.
$quoted = $arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }
$process = Start-Process -FilePath $UnityEditor -ArgumentList $quoted -PassThru -WindowStyle Hidden
if (!$process.WaitForExit(1800000)) { $process.Kill(); throw "Unity export timed out. Read $log" }
if ($process.ExitCode -ne 0) { throw "Unity failed ($($process.ExitCode)). Read $log" }
if (!(Select-String -LiteralPath $log -Pattern 'BLOCKLAB_SCENE_VALIDATED' -Quiet)) { throw "Scene validation did not finish. Read $log" }
if (!$VerifyOnly) {
    if (!(Test-Path (Join-Path $exportPath 'src/main/AndroidManifest.xml'))) { throw 'Unity export is incomplete.' }
    & "$PSScriptRoot/patch-unity-export.ps1"
}
Write-Host "Unity checks passed. Log: $log"
