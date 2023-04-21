import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)")) {
      mkdir "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)" -ea silentlycontinue
    }
    
    $client.DownloadFile($Latest.URL, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")
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
    "(^\s*url\s*=\s*)('.*')"      = "`$1'$($Latest.internalsite)'"
    "(^\s*checksum\s*=\s*)('.*')" = "`$1'$($Latest.checksum)'"
  }
 }
}


function global:au_GetLatest {
  $packagename = "citrix-workspace"
  $releases = 'https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html'
  $downloadPage = Invoke-WebRequest -Uri $releases -usebasicparsing
  $re = 'Version: ([\d]+\.[\d\.]+)'
  $version = ([regex]::match($downloadPage.Content, $re).Groups[1].Value) 
  $url = "https://downloadplugins.citrix.com/Windows/CitrixWorkspaceApp.exe"
  
  
  $filename = ($URL.Substring($URL.LastIndexOf("/") + 1))

  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"

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