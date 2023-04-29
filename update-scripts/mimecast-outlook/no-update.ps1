import-module au

function global:au_BeforeUpdate() {

  $client = New-Object System.Net.WebClient
  try {
    $nospace_zip = ($Latest.filename).replace(" ","")
    $client.DownloadFile($Latest.URL, "$($env:au_chocopackagepath)\$($Latest.packagename)\$($nospace_zip)")
    $shell= New-Object -Com Shell.Application
    $zip = $shell.NameSpace("$($env:au_chocopackagepath)\$($Latest.packagename)\$($nospace_zip)")
    $msi = $zip.Items() | where-object {$_.path -like '*.msi'}
    $msifilename = ($latest.filename).replace('.zip','.msi')
    $nospace_msifilename = $msifilename.replace(" ","")
    $shell.namespace("$($env:au_chocopackagepath)\$($Latest.packagename)").copyhere($msi)
    move-item "$($env:au_chocopackagepath)\$($Latest.packagename)\$msifilename" "$($env:au_chocopackagepath)\$($Latest.packagename)\$nospace_msifilename"
    
  }
  finally {
    $client.Dispose()
  }

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$nospace_msifilename" | ForEach-Object Hash

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
  $packagename = "mimecast-outlook-x64"
  [xml]$mimecastxml = Invoke-WebRequest http://updates-uk.mimecast.com/update/descriptors/mfo/latest -useBasicParsing
  $version = $mimecastxml.'mimecast-update'.updates.update[1]."product-key".version
  $url = $mimecastxml.'mimecast-update'.updates.update[1].download.url
  $filename = ("Mimecast for outlook $($version) (x64).zip")
  $isfilename = $filename.replace(' ','')
  $is =  "$($env:au_chocopackages)/$($packagename)/$($isfilename)"

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