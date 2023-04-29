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
  $packagename = "wireshark"
  $releases = 'https://www.wireshark.org/download.html'
  $download_page = Invoke-WebRequest $releases -usebasicparsing
  [regex]$re = 'Stable Release: \d+.\d+.\d+'
  $versionMatch = $re.Match($download_page.content)
  $version = $versionMatch.value -replace "Stable Release: ", ""

  $URL = $download_page.links | Where-Object {($_.href -like "*win64*") -AND ($_.href -like "*$version*")} | Select-Object -ExpandProperty href
  $filename = $URL[0].Substring($URL[0].LastIndexOf("/") + 1)


  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL          = $URL[0]
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none