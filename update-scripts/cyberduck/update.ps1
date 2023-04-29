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
  $packagename = 'cyberduck'
  $releaseUrl = 'https://cyberduck.io/download'
  $versionRegEx = 'Cyberduck-Installer-([0-9\.]+)'

  $releasePage = Invoke-WebRequest -Uri $releaseUrl -UseBasicParsing
  $version = ([regex]::match($releasePage.Content, $versionRegEx).Groups[1].Value)
  $version = $version.substring(0,$version.length-1)
  
  $URL = $releasePage.Links | Where-Object outerHTML -match $versionRegEx | Select-Object -First 1 -Expand href

  $filename = $URL.Substring($URL.LastIndexOf("/") + 1)

  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{ URL = $URL
     Version = $version
     internalsite = $is
     packagename = $packagename
     filename = $filename
  }
}

function global:au_AfterUpdate ($Package)  {
  $ROVArgs = @{
    maximumversions = 2
    packagename = 'cyberduck'
    matcher = '^\s*url\s*= ''chocoservergoeshere'''
  }
  Remove-ObsoleteVersion @ROVArgs
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none