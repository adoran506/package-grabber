import-module au
import-module "$PSScriptRoot\..\_scripts\au_extensions.psm1"


function global:au_BeforeUpdate() {

  $Latest.ChecksumType = "sha256"
  $Latest.Checksum = Get-FileHash -Algorithm $Latest.ChecksumType64 -Path "$($env:au_chocopackagepath)\$($Latest.packagename)\$($Latest.version)\$($Latest.filename)" | % Hash
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
  $packagename = "fileopen"
  $ProgressPreference = "SilentlyContinue"
  $url = 'https://plugin.fileopen.com/current/FileOpenInstaller64.msi'
  $filename = $url | split-path -leaf
  $stagepath = "$($env:au_chocopackagepath)\$($packagename)"
  $stagefile = "$($stagepath)\$($filename)"

  Invoke-WebRequest -Uri ($url) -outfile $stagefile -usebasicparsing
  [string]$version = (Get-MSIVersion $stagefile)
  $version = $version.Trim()
  $targetpath = "$($stagepath)\$($version)"
  
  if (!(Test-Path $targetpath)) {
    mkdir $targetpath

    try {
      Move-Item $stagefile $targetpath -ErrorAction Stop
    }
    catch {
      # sometimes the msi file is locked due to get-msiversion cleanup.  racy
      [System.GC]::Collect()
      [System.GC]::WaitForPendingFinalizers()
      start-sleep 5
      Move-Item $stagefile $targetpath
    }
  }

  $is =  "$($env:au_chocopackages)/$($packagename)/$($version)/$($filename)"


  @{ URL          = $url
     Version      = $version
     internalsite = $is
     filename     = $filename
     packagename  = $packagename
  }
}

Update-Package