import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"

function global:au_BeforeUpdate() {

  #workaround sourceforge download redirect using ff useragent string
  invoke-webrequest -uri $latest.url -Outfile "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.filename)" -UserAgent [Microsoft.Powershell.Commands.PSUserAgent]::Chrome
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
  $packagename = "winscp"
  $releases = 'https://winscp.net/eng/download.php'
  $re  = 'WinSCP.+\.exe$'
  $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
  
  $urlsuffix = @($downloadpage.links | ? href -match $re) -notmatch 'beta|rc' | % href
  $urlsuffix = $urlsuffix.Replace('..','')
  
  $releaseurl = 'https://winscp.net' + $urlsuffix
  
  $version   = $releaseurl -split '-' | select -Last 1 -Skip 1
  $filename = $releaseurl -split '/' | select -last 1

  $url = "https://sourceforge.net/projects/winscp/files/WinSCP/$version/$filename/download"
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