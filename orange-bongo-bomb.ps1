<#	
	.NOTES
	=========================NOTES=========================
	 Created on:   	25. JAN 2022
	 Created by:   	Mirco Ingenito
	 Organization: 	https://enito.ch
	 Filename:     	orange-bongo-bomb.ps1

	=========================DESCRIPTION=========================
	.DESCRIPTION
	Verify, disable or enable restriction of M365-Group creation.
    
    IMPORTANT: Existing security-group in AAD required for (Option 2) .
#>

Function Show-Menu
{
     param (
           [string]$Title = "Manage 'who' can create Microsoft365-Groups in your Tenant"
     )
     cls
     Write-Host "=============================================================="
     Write-Host "| $Title |"
     Write-Host "=============================================================="
     Write-Host ""
     Write-Host "Available Options:"
     Write-Host "------------------"
     Write-Host ""
     Write-Host "1: Verify if restrictions are enabled... $a1"
     Write-Host "2: Restrict M365-Group creation to a specific group in your AAD... $a2"
     Write-Host "3: Allow all users in your tenant to create M365-Groups... (enabled by default) $a3"
     
}

Function Opt3EnableAllUsers {


$GroupName = ""
$AllowGroupCreation = $True

Connect-AzureAD

$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID)
{
    $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
    $settingsCopy = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settingsCopy
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
}

$settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
$settingsCopy["EnableGroupCreation"] = $AllowGroupCreation

if($GroupName)
{
  $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
} else {
$settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
}
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy

(Get-AzureADDirectorySetting -Id $settingsObjectID).Values



}


do
{
     Show-Menu
     Write-Host ""
     $input = Read-Host "-->What would you like to do? ('Q' to quit)"
     switch ($input)
     {
           '1' {
                cls
                'You selected Option #1: --> Verify if restrictions are enabled...'
           } '2' {
                cls
                'You selected Option #2: --> Restrict M365-Group creation to a specific group in your AAD...'
           } '3' {
                cls
                Write-Host "Running script..."

                Opt3EnableAllUsers
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')