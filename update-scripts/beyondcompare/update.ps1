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
  $packagename = "beyondcompare"
  $releases = 'https://www.scootersoftware.com/download.php'
  $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
  
  $matches = $null
  $re = 'Current Version:(&nbsp;|\s)*(?<release>\d{1,}\.\d{1,}\.\d{1,}), build (?<build>\d{1,}), released (?<month>[A-Za-z]{3,4})\.? (?<day>[0-9]{1,2})\, (?<year>[0-9]{4})'
  $isMatch = $downloadPage.content -match $re
  $version = $matches.release + "." + $matches.build
  $url = "https://www.scootersoftware.com/BCompare-$($version).exe"
  
  
  $filename = ($URL.Substring($URL.LastIndexOf("/") + 1))

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