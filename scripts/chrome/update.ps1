import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate {

  $client = New-Object System.Net.WebClient
  try {
    $client.DownloadFile($Latest.URL64, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)")
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum64 = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" | % Hash

}

function global:au_SearchReplace {
  @{
    ".\tools\chocolateyInstall.ps1" = @{
      "(?i)(^\s*url\s*=\s*)('.*')" = "`$1'$($Latest.internalsite)'"
      "(?i)(^\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
    }
  }
}

function global:au_GetLatest {
  $releases = 'http://omahaproxy.appspot.com/all?os=win&amp;channel=stable'
  $paddedUnderVersion = '57.0.2988'
  $packagename = "chrome"
  $upstream_Url = 'https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi'
  $ProgressPreference = "SilentlyContinue"

  $release_info = Invoke-WebRequest -Uri $releases -UseBasicParsing
  $version = $release_info | ForEach-Object Content | ConvertFrom-Csv | ForEach-Object current_version

  $is =  "$($env:au_chocopackages)/$($packagename)/googlechromestandaloneenterprise64-$($version).msi"
  $filename = $is.Substring($is.LastIndexOf("/") + 1)
  
  @{
    URL64 = $upstream_Url
    Version = Get-PaddedVersion -Version $version -OnlyBelowVersion $paddedUnderVersion -RevisionLength 5
    RemoteVersion = $version
    PackageName = $packagename
    Internalsite = $is
    filename = $filename
  }
}

function global:au_AfterUpdate ($Package)  {

  $ROVArgs = @{
    maximumversions = 2
    packagename = 'chrome'
    matcher = '^\s*url\s*= ''chocoservergoeshere'''
  }
  Remove-ObsoleteVersion @ROVArgs
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none
