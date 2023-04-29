import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

    if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")) {
      mkdir "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)" -ea silentlycontinue
    }


  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType64 = "sha256"
  $Latest.Checksum64 = Get-FileHash -Algorithm $Latest.ChecksumType64 -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)" | ForEach-Object Hash
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
  # used to allow a stronger than default tls version to be used if required.
  [Net.ServicePointManager]::SecurityProtocol="tls12,tls11,tls"

  $packagename = 'ssms18'
  $releaseUrl = 'https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms'
  $versionRegEx = 'Build number: ([0-9\.]+)'

  $releasePage = Invoke-WebRequest -Uri $releaseUrl -UseBasicParsing
  $version = ([regex]::match($releasePage.Content, $versionRegEx).Groups[1].Value)

  $URL64 = 'https://aka.ms/ssmsfullsetup'

  $filename = 'SSMS-Setup-ENU.exe'

  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"

  @{ URL64        = $URL64
     Version      = $version
     internalsite = $is
     packagename  = $packagename
     filename     = $filename
  }
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none