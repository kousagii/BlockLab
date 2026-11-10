param()
. "$PSScriptRoot/environment.ps1"
$log=Join-Path $LogRoot 'unity-previews.log'
$arguments=@('-batchmode','-force-d3d11','-buildTarget','Android','-projectPath',(Join-Path $RepoRoot 'unity'),
    '-executeMethod','BlockLabPreviewCapture.Run','-logFile',$log)
$quoted=$arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }
$process=Start-Process -FilePath $UnityEditor -ArgumentList $quoted -PassThru -WindowStyle Hidden
if (!$process.WaitForExit(300000)) { $process.Kill(); throw "Unity previews timed out. Read $log" }
if ($process.ExitCode -ne 0 -or !(Select-String -LiteralPath $log -Pattern 'BLOCKLAB_PREVIEWS_PASSED' -Quiet)) {
    throw "Unity previews failed. Read $log"
}
if (Select-String -LiteralPath $log -Pattern 'Shader error|MissingComponentException|error CS' -Quiet) { throw "Preview rendering errors. Read $log" }
Write-Host "Unity scene previews saved in docs/screenshots. Log: $log"
