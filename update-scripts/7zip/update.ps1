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
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | % Hash

}
  
function global:au_SearchReplace {
@{
  'tools\chocolateyInstall.ps1' = @{
    "(^\s*url64bit\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.checksum)'"
  }
 }
}

function global:au_GetLatest {
  $packagename = "7zip"
  $upstream_Url   = 'http://www.7-zip.org/'
  $releases = "${upstream_Url}download.html"
  $download_page = Invoke-WebRequest $releases -usebasicparsing
  [regex]$re = "Download 7\-Zip ([\d\.]+) \([\d]{4}[\-\d]+\)"
  $versionMatch = $re.Match($download_page.content)
  $version = $versionMatch.Groups[1].value
  $URLS = $download_page.links | ? href -match "7z$($version -replace '\.','')(\-x64)?\.msi$" | select -expand href
  $url64 = $URLS | ? { $_ -match "x64" } | select -first 1

  $filename = $URL64.Substring($URL64.LastIndexOf("/") + 1)
  
  
  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL64 = $upstream_Url + $url64
     Version = $version
     internalsite = $is
     packagename = $packagename
     filename = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none