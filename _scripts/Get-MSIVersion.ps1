<#
.Synopsis
   Gets the version from MSI file
.DESCRIPTION
   This script gets the version from MSI file.
.EXAMPLE
   ./Get-MSIVersion.ps1 -msifile .\mymsi.msi

#>

function Get-MSIVersion() {
  param (
      $MSIFile
  )

  try {
    [IO.FileInfo]$msifile = get-item $msifile
    $windowsInstaller = New-Object -com WindowsInstaller.Installer
    $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null,$windowsInstaller, @($MSIFile.FullName, 0))
    $query = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
    $View = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $database, ($query))
    $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)

    $record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)
    $productVersion = $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 1)
    $view.GetType().InvokeMember("Close", "InvokeMethod", $null, $view, $null)
    [Void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($database)
    [Void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($windowsInstaller)
    $database = $null
    return $productVersion
    
  }
  catch {
      throw "Failed to get MSI Product Version. Uninstall will need to specify this explicitly" -f $_
  }
}