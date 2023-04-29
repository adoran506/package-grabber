import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum64 = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | ForEach-Object Hash

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
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $packagename = "python3"
  $releases = 'http://www.python.org/downloads/'
  $version_page = Invoke-WebRequest -Uri $releases -usebasicparsing
  $release_href = $version_page.links | Where-Object href -match '^/downloads/release/python-3\d+/$'
  $release_url = "http://www.python.org$($release_href[0].href)"

  $download_page = Invoke-WebRequest -Uri $release_url -usebasicparsing
  $url64 = $download_page.links | Where-Object href -match "python-.+amd64\.(exe|msi)$" | select-object -first 1 -expand href

  $filename = $url64.Substring($url64.LastIndexOf("/") + 1)
  $urlarray = $url64 -split "/"
  $version = $urlarray[-2]

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version       = $version
      URL64         = $url64
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none