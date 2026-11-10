param()
. "$PSScriptRoot/environment.ps1"
$log = Join-Path $LogRoot 'unity-workspace-tests.log'
$arguments = @('-batchmode','-nographics','-buildTarget','Android','-projectPath',
    (Join-Path $RepoRoot 'unity'),'-executeMethod','BlockLabWorkspaceChecks.Run','-logFile',$log)
$quoted = $arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }
$process = Start-Process -FilePath $UnityEditor -ArgumentList $quoted -PassThru -WindowStyle Hidden
if (!$process.WaitForExit(600000)) { $process.Kill(); throw "Unity tests timed out. Read $log" }
if ($process.ExitCode -ne 0 -or !(Select-String -LiteralPath $log -Pattern 'BLOCKLAB_WORKSPACE_CHECKS_PASSED' -Quiet)) {
    throw "Unity workspace tests failed. Read $log"
}
Write-Host "Unity Play Mode workspace checks passed. Log: $log"
