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
  $packagename = "factset"
  $releases = "https://www.factset.com/download"
  $downloadlink =  "https://support.factset.com/workstation/gr/64"
  $download_page = Invoke-WebRequest $releases -usebasicparsing
  [regex]$re = 'Version:[\D]+([\d]+\.[\d\.]+)'
  $versionMatch = $re.Match($download_page.content)
  $version = $versionMatch.Groups[1].value
  $URL = Get-RedirectUrl $downloadlink
  $filename = $URL.Substring($URL.LastIndexOf("/") + 1)

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL          = $downloadlink
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none