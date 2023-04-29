import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType64 = "sha256"
  $Latest.Checksum64 = Get-FileHash -Algorithm $Latest.ChecksumType64 -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

}


function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url64bit\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.checksum64)'"
  }
 }
}


function global:au_GetLatest {
  $packagename = "postman"
  $releases = "https://dl.pstmn.io/changelog?channel=stable&platform=win"
  $downloadraw = (Invoke-WebRequest $releases -UseBasicParsing).content
  $json = convertfrom-json $downloadraw
  $version = ($json.changelog |select -First 1).name
  $url = ($json.changelog |select -First 1).assets.url
  $filename = ($json.changelog |select -First 1).assets.name


  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version       = $version
      URL64         = $url
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none