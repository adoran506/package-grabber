import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient

  if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")) {
    mkdir "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)" -ea silentlycontinue
  }


  try {
    $client.DownloadFile($Latest.URL, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)" | % Hash
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
  $packagename = 'slack'
  $releaseUrl = 'https://slack.com/downloads/windows'
  $versionRegEx = '.*Version ([\d]+\.[\d\.]+)'

  $downloadPage = Invoke-WebRequest -Uri $releaseUrl -UseBasicParsing

  $version = ([regex]::match($downloadPage.Content, $versionRegEx).Groups[1].Value)
  $filename = $URL.Substring($URL.LastIndexOf("/") + 1)

  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"

  $URL = "https://downloads.slack-edge.com/releases/windows/$version/prod/x64/SlackSetup.msi"

  @{ URL = $URL
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none