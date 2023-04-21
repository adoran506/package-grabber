import-module au

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
  $releases = 'https://data.services.jetbrains.com//products/releases?code=DG&latest=true&type=release'
  $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
  $packagename = "datagrip"
  $json = $downloadpage.Content | ConvertFrom-Json
  $version = $json.dg.version
  $url   = $json.dg.downloads.windows.link
  $filename = $URL.Substring($URL.LastIndexOf("/") + 1)
  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version      = $version
      URL        = $url
      packagename = $packagename
      filename = $filename
      internalsite = $is
  }
}


# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none