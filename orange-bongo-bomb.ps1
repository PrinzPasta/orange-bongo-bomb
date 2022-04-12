<#	
	.NOTES
	=========================NOTES START=========================
	 Created on:   	05. April 2022
	 Created by:   	Mirco Ingenito
	 Organization: 	https://enito.ch
	 Filename:     	orange-bongo-bomb.ps1

	=========================DESCRIPTION=========================
	.DESCRIPTION
	Verify, disable or enable restriction of M365-Group creation.
    
    IMPORTANT: Existing security-group in AAD required for (Option 2) .
   	=========================NOTES END=========================

#>

$c = Get-Credential
Connect-AzureAD -Credential $c

Function Show-Menu
{
     
     param (
           [string]$Title = "Manage 'who' can create Microsoft365-Groups in your Tenant"
     )
     Clear-Host
     Write-Host "=============================================================="
     Write-Host "| $Title |"
     Write-Host "=============================================================="
     Write-Host ""
     Write-Host "Logged in as: "  $Cred.Username "! "
     Write-Host ""
     Write-Host "Available Options:"
     Write-Host "------------------"
     Write-Host ""
     Write-Host "1: Verify if restrictions are enabled... $a1"
     Write-Host "2: Restrict M365-Group creation to a specific group in your AAD... $a2"
     Write-Host "3: Allow all users in your tenant to create M365-Groups... (Microsoft default setting) $a3"
     
}

Function Opt1VerifyRestrictions
{
## Get all Settings from Group.Unified AAD-SettingsTemplate and store information into $settings

$Setting = Get-AzureADDirectorySetting | ? { $_.DisplayName -eq "Group.Unified"}

##Can M365 Groups be created by everyone in the tenant?
$EnableGroupCreationGlobally = $Setting.Values | ? {$_.Name -eq "EnableGroupCreation"}


## Get Group-ID which is enabled to create M365Groups
$GroupCreationAllowedGroupID = $Setting.Values | ? {$_.Name -eq "GroupCreationAllowedGroupID"}

$Group = Get-AzureADGroup | ?{$_.ObjectId -eq $GroupCreationAllowedGroupID.Value}



if ($EnableGroupCreationGlobally.Value -eq "false"){

Write-Host "Members of the following AAD-Group can create M365-Groups:" -ForegroundColor Yellow
Write-Host $Group.DisplayName -BackgroundColor DarkYellow

} else  {

Write-Host ("Creation of M365-Groups is not restricted.") -ForegroundColor Green

}

}


Function Opt2RestrictM365GrpCreation 
{
     $GroupName = Read-Host -Prompt 'Insert AAD Security Group Name'

     $AllowGroupCreation = $False
     
     Write-Host 'Please login as Global Administrator in the prompted window...' -ForegroundColor Yellow -BackgroundColor DarkGreen
     

     Write-host 'Running script to allow M365-Group creation only for Members of the following AAD Security Group: ' -ForegroundColor Yellow -BackgroundColor DarkGreen `n
     Write-host $GroupName -ForegroundColor Yellow -BackgroundColor DarkGreen
          
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


Function Opt3EnableAllUsers 
{
Write-Host 'Please login as Global Administrator in the prompted window...' -ForegroundColor Yellow -BackgroundColor DarkGreen
$GroupName = ""
$AllowGroupCreation = $True


Write-host 'Running script to allow all users in your tenant to create M365-Groups' -ForegroundColor Yellow -BackgroundColor DarkGreen

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
     $menuInput = Read-Host "-->What would you like to do? ('q' to quit)"
     switch ($menuInput)
     {
           '1' {
                Clear-Host
                Write-Host 'Option #1 selected. -->Verify if M365-Group creation is restricted.' `n
                Opt1VerifyRestrictions
           } '2' {
                Clear-Host
                Write-Host 'Option #2 selected. --> Restrict M365-Group creation to a specific group in your AAD.' `n
                
                Opt2RestrictM365GrpCreation
           } '3' {
                Clear-Host
                Write-Host "Option 3 selected. --> Allow all users in your tenant to create M365-Groups." `n

                Opt3EnableAllUsers
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')
