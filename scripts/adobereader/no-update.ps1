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
  $packagename = "adobereader"
  $releases = "https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"
  $downloadPage = Invoke-WebRequest -Uri $releases -UseBasicParsing
  # url has no 2x

  $versionRegEx = '23\.([\d]+\.[\d\.]+)'
  $version = ([regex]::match($downloadPage.Content, $versionRegEx).Groups[1].Value)
  $realversion = "23$($version)"
  $version_nosemver = $realversion.Replace('.','')
  $url = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/$($version_nosemver)/AcroRdrDC$($version_nosemver)_en_US.exe"
  $filename = ($URL.Substring($URL.LastIndexOf("/") + 1))

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version       = $realversion
      URL           = $url
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none