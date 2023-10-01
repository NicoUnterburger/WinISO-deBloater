cls
#APPX Packages to Remove 
$apps = 
    {Clipchamp.Clipchamp},
    {Microsoft.GetHelp},
    {Microsoft.Getstarted},
    {Microsoft.Microsoft3DViewer},
    {Microsoft.MicrosoftOfficeHub},
    {Microsoft.MicrosoftSolitaireCollection},
    {Microsoft.MicrosoftStickyNotes},
    {Microsoft.BingNews},
    {Microsoft.GamingApp},
    {Microsoft.MixedReality.Portal},
    {Microsoft.Office.OneNote},
    {Microsoft.OneDriveSync},
    {Microsoft.People},
    {Microsoft.SkypeApp},
    {Microsoft.WindowsMaps},
    {Microsoft.WindowsFeedbackHub},
    {Microsoft.Xbox.TCUI},
    {Microsoft.XboxApp},
    {Microsoft.XboxGameOverlay},
    {Microsoft.XboxGamingOverlay},
    {Microsoft.XboxIdentityProvider},
    {Microsoft.XboxSpeechToTextOverlay},
    {Microsoft.XboxGameCallableUI},
    {Microsoft.YourPhone},
    {Microsoft.ZuneMusic},
    {Microsoft.ZuneVideo},
    {Microsoft.Wallet},
    {microsoft.windowscommunicationsapps},
    {MicrosoftCorporationII.QuickAssist}

$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
Set-Alias Start-SevenZip $7zipPath
$workingDir = "C:\TEMP\winISO-deBloat\"

# Generate WorkingDirs 
If(!(test-path -PathType container $workingDir)) {
      New-Item -ItemType Directory -Path $workingDir
}
$isoOutput = $workingDir + "ISOoutput\"
Get-ChildItem $workingDir -Recurse | Remove-Item -Recurse
If(!(test-path -PathType container $isoOutput)) {
      New-Item -ItemType Directory -Path $isoOutput
}
cd $isoOutput

# Extract ISO-File
$isoPath = Read-Host -Prompt "Please enter path for Windows ISO file!"
Start-SevenZip  x $isoPath
If(Test-Path -PathType Leaf -Path $isoOutput\sources\install.wim) {
    Copy-Item $isoOutput\sources\install.wim $workingDir
    $iso = "$workingDir\install.wim"
}

If(Test-Path -PathType Leaf -Path $isoOutput\sources\install.esd) {
    Copy-Item $isoOutput\sources\install.esd $workingDir
    $iso = "$workingDir\install.esd"
}

# Remove unused Windows Versions (like Home, Enterprise or N-Versions)
Write-Host "Start deBloat Windows ISO:" $iso
Write-Host "1. remove unused Windows Versions like Home, Enterprise or N-Versions"
Write-Host "before:"

Get-WindowsImage -ImagePath $iso | ft ImageIndex, ImageName
$value = Get-WindowsImage -ImagePath $iso | sort ImageIndex | select -Last 1
$maxindex = $value.ImageIndex
for ($i=$maxindex; $i -gt 0; $i--) {
    $image = Get-WindowsImage -ImagePath $iso -Index $i
    if (($image.ImageName -ne "Windows 10 Pro") -AND ($image.ImageName -ne "Windows 11 Pro")) {Remove-WindowsImage -ImagePath $iso -Index $i -CheckIntegrity}
}

Write-Host "after:"
Get-WindowsImage -ImagePath $iso | ft ImageIndex, ImageName

If($iso -Like "*.esd") {
    dism /export-image /SourceImageFile:$iso /SourceIndex:1 /DestinationImageFile:"$workingDir\install.wim" /Compress:max /CheckIntegrity
    $iso = "$workingDir\install.wim"
    Rename-Item -Path $workingDir\install.esd -NewName install.esd.old
}

# Remove unwanted Bloatware-Apps 
md WindowsImage
Write-Host "Mount ISO"
Mount-WindowsImage -ImagePath $iso -Index 1 -Path .\WindowsImage

Write-Host "2. remove bloatware AppX-Packages:"
foreach ($app in $apps) {
    Write-Host "Try to Remove AppX-Package: " $app
    $selected = Get-AppxProvisionedPackage -Path .\WindowsImage | Where -filterScript {$_.DisplayName -like $app}
    Remove-AppxProvisionedPackage -Path .\WindowsImage -PackageName $selected.PackageName
}

Get-AppxProvisionedPackage -Path .\WindowsImage | FT DisplayName, PackageName
Write-Host "Dismount ISO"
Dismount-WindowsImage -Path .\WindowsImage -Save
rd WindowsImage

# Compress wim File to ESD
dism /export-image /sourceimagefile:$iso /sourceIndex:1 /Destinationimagefile:$workingdir\install.esd /compress:recovery
Remove-Item $isoOutput\sources\install.wim
Remove-Item $isoOutput\sources\install.esd
Copy-Item $workingDir\install.esd $isoOutput\sources\

Write-Host ""
Write-Host "New 'install.esd'-File was generated successfull and also replaced in workingfolder."
Write-Host "Bitte den Ordner " $isoOutput "als .iso-Datei konvertieren (z.B. Tool Folder2ISO)"
Write-Host "Next, create an ISO File from working Folder (" + $isoOutput + " with Tool below, or use install.esd for PXE-Server"
Write-Host "https://www.heise.de/download/product/folder2iso-55117"
