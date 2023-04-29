import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {

    if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")) {
      mkdir "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)" -ea silentlycontinue
    }

    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)" | ForEach-Object Hash

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
  $packagename = 'powerbi'
  $releaseUrl = 'https://www.microsoft.com/en-us/download/details.aspx?id=58494'
  $downloadUrl = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=58494'
  $versionRegEx = '<p>([0-9\.]+)</p>'
  $downloadLinkRegEx = 'PBIdesktopSetup_x64'

  $releasePage = Invoke-WebRequest -Uri $releaseUrl -UseBasicParsing
  $version = ([regex]::match($releasePage.Content, $versionRegEx).Groups[1].Value)
  $downloadPage = Invoke-WebRequest -Uri $downloadUrl -UseBasicParsing

  $URL64 = $downloadPage.Links | Where-Object outerHTML -match $downloadLinkRegEx | Select-Object -First 1 -Expand href

  $filename = $URL64.Substring($URL64.LastIndexOf("/") + 1)

  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"

  @{ URL64        = $URL64
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

function global:au_AfterUpdate ($Package)  {

}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none