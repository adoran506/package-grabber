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

  $domain = 'https://github.com'
  $releases = "$domain/git-for-windows/git/releases/latest"
  $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
  $re64 = "/git-for-windows/git/tree" #results in tag with latest version + extra characters, needs to be trimmed.
  $links = $downloadpage.links | Where-Object href -match $re64 | Select-Object -First 1 -expand href | ForEach-Object { $domain + $_ }
  $vers1 = $links -split '/' | Select-Object -Last 1
  $vers2 = $vers1.Substring(1, $vers1.length - 1)
  $version = $vers2.Substring(0, $vers2.length - 10)
  # url is "hardcoded" for current download url with versions plugged in
  $url = "https://github.com/git-for-windows/git/releases/download/$vers1/Git-$version-64-bit.exe"

  $packagename = "git"

  $filename = ($url.Substring($url.LastIndexOf("/") + 1))
  $is =  "$($env:au_chocopackages)/$($packagename)/$($filename)"

  @{
      Version       = $version
      URL           = $url
      packagename   = $packagename
      filename      = $filename
      internalsite  = $is
  }
}

function global:au_AfterUpdate ($Package)  {

  $ROVArgs = @{
    maximumversions = 2
    packagename = 'git'
    matcher = '^\s*url\s*= ''https://chocopackages.3rdpoint.corp/git/(.*)'''
  }
  Remove-ObsoleteVersion @ROVArgs
}

# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none