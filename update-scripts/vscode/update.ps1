import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"
function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

}


function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum\s*=\s*)('.*')" = "`$1'$($Latest.checksum)'"
  }
 }
}


function global:au_GetLatest {
  $releases     = 'https://github.com/microsoft/vscode/releases/latest'
  $versionPage  = Invoke-WebRequest -Uri $releases -usebasicparsing
  $re           = '\/microsoft\/vscode\/tree\/.*'
  $version1     = $versionPage.links | Where-Object href -match $re | Select-Object -Expand href -First 1
  $version      = $version1 -split '/' | Select-Object -Last 1

  $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"

  $filename = "VSCodeSetup-x64-$version.exe"

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version       = $version
      URL           = $url
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none