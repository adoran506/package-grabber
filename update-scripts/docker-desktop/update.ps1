import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {

    if (!(Test-Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)")) {
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
    $packagename = "docker-desktop"
    $releases = "https://download.docker.com/win/stable/appcast.xml"
    $ProgressPreference = "SilentlyContinue"
    [xml]$download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing
    $regex = $download_page.rss.channel.item.title | Select-String -Pattern "([0-9.]+).*\((\d+)\)"
    $versionprefix = (($regex.Matches.Groups[1]).value).Substring(0,($regex.Matches.Groups[1]).value.LastIndexOf(('.')))
    $version = "$versionprefix.$($regex.Matches.Groups[2])"

    # AU uses [Uri]::IsWellFormedUriString whereby spaces are not allowed in the Uri.
    $upstream_Url = "https://desktop.docker.com/win/stable/amd64/Docker Desktop Installer.exe" -replace ' ', '%20'

    #get rid of spaces to avoid on-premise issues

    $orig_filename = ($upstream_Url.Substring($upstream_Url.LastIndexOf("/") + 1))
    $filename = $orig_filename -replace '%20',' '

    $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($orig_filename)"

    return @{ Version      = "$version"
              URL          = "$upstream_url"
              internalsite = "$is"
              filename     = "$filename"
              packagename  = "$packagename"
    }
}


# we get our own checksum since we download and handle in beforeupdate
Update-Package -ChecksumFor none