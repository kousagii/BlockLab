param()
. "$PSScriptRoot/environment.ps1"
$library = Join-Path $AppRoot 'android/unityLibrary'
$gradleFile = Join-Path $library 'build.gradle'
if (!(Test-Path $gradleFile)) { throw 'Export Unity first.' }
$gradle = [IO.File]::ReadAllText($gradleFile)
# Keep IL2CPP's Unity-supported NDK independent from the Flutter module's NDK.
$gradle = [regex]::Replace($gradle, '(?m)^\s*ndkPath\s+.*$', '')
$gradle = [regex]::Replace($gradle, '(?m)^\s*ndkVersion\s+.*$', '')
$marker = '// BlockLab local Unity toolchain'
if (!$gradle.Contains($marker)) {
    $gradle += @'

// BlockLab local Unity toolchain
 def blockLabLocal = new Properties()
 rootProject.file('local.properties').withInputStream { blockLabLocal.load(it) }
 android.ndkPath = blockLabLocal.getProperty('unity.ndk')
 android.ndkVersion = '23.1.7779620'
'@
}
$gradle = [regex]::Replace($gradle, 'commandLineArgs.add\("--tool-chain-path=[^"\r\n]*"\)', 'commandLineArgs.add("--tool-chain-path=" + android.ndkPath)')
[IO.File]::WriteAllText($gradleFile, $gradle)
# A non-AR sandbox must not acquire device restrictions from an old export.
[xml]$manifest = Get-Content (Join-Path $library 'src/main/AndroidManifest.xml')
$ns = New-Object Xml.XmlNamespaceManager($manifest.NameTable)
$ns.AddNamespace('a','http://schemas.android.com/apk/res/android')
foreach ($node in @($manifest.SelectNodes('//uses-permission[@a:name="android.permission.CAMERA"] | //uses-feature[@a:name="android.hardware.camera.ar"] | //uses-feature[@a:name="com.google.ar.core.depth"] | //meta-data[@a:name="com.google.ar.core"]',$ns))) {
    [void]$node.ParentNode.RemoveChild($node)
}
$manifest.Save((Join-Path $library 'src/main/AndroidManifest.xml'))
# The supplied scene currently has no StreamingAssets. Keep the property explicit.
$properties = Join-Path $AppRoot 'android/gradle.properties'
$text = [IO.File]::ReadAllText($properties)
if ($text -notmatch '(?m)^unityStreamingAssets=') { [IO.File]::AppendAllText($properties, "`nunityStreamingAssets=`n") }
Write-Host 'Applied repeatable Unity export configuration.'
