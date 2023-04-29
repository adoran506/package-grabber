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
  $releases = 'https://classic.yarnpkg.com/en/docs/install#windows-stable'
  $packagename = "yarn"
  $version_page = Invoke-WebRequest -Uri $releases -usebasicparsing
  [regex]$re = "[0-9].[0-9]{1,}.[0-9]{1,}"
  $release_href = $version_page.links | Where-Object outerHTML -match '<a href="https://github.com/yarnpkg/yarn/blob/master/CHANGELOG.md">' | select-object outerHTML
  $download_url = "https://classic.yarnpkg.com/latest.msi"

  $version = ($re.Match($release_href.outerhtml)).value
  $filename = "yarn-$version.msi"
  
  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL          = "$download_url"
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none