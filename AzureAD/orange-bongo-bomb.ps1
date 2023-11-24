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

Import-Module AzureAD

Function Show-Menu
{
     
     Clear-Host
     Write-Host "==============================================================" -ForegroundColor Blue -BackgroundColor White
     Write-Host "| Manage 'who' can create Microsoft365-Groups in your Tenant |" -ForegroundColor Blue -BackgroundColor White
     Write-Host "==============================================================" -ForegroundColor Blue -BackgroundColor White
     Write-Host ""
     Write-Host ("Available Options:") -ForegroundColor Black -BackgroundColor Green
     Write-Host "------------------" -ForegroundColor Black -BackgroundColor Green
     Write-Host "1: Verify if restrictions are enabled... $a1" -ForegroundColor Black -BackgroundColor Green
     Write-Host "2: Restrict M365-Group creation to a specific group in your AAD... $a2" -ForegroundColor Black -BackgroundColor Green
     Write-Host "3: Allow all users in your tenant to create M365-Groups... (Microsoft default setting) $a3" -ForegroundColor Black -BackgroundColor Green
     Write-Host ""
     Write-Host ""
     Write-Host ("IMPORTANT: Requirements to run the:") -ForegroundColor Black -BackgroundColor Yellow
     Write-Host "------------------------------------" -ForegroundColor Black -BackgroundColor Yellow
     Write-Host "--> PowerShell 5.1 is required (AzureAD cmdlets is not supported in PowerShell Core 7.x)" -ForegroundColor Black -BackgroundColor Yellow
     Write-Host "--> Script can  o n l y  be executed by a Global Administrator in your Tenant (We are touching the Settings for Group Creation)" -ForegroundColor Black -BackgroundColor Yellow
     Write-Host "--> You have to login for each Option you select with your credentials (have not found a way yet to store credentials for Accounts with MFA)" -ForegroundColor Black -BackgroundColor Yellow
     Write-Host "--> You have to login for each Option you select with your credentials (have not found a way yet to store credentials for Accounts with MFA)" -ForegroundColor Black -BackgroundColor Yellow
     Write-Host "--> For Option 2 --> an existing Security Group in your Azure Active Directory"
}

Function Opt1VerifyRestrictions
{
     Write-host 'Please Login to execute the Action (separate window). ' -ForegroundColor Black -BackgroundColor Yellow `n
     
     Connect-AzureAD

     ## Get all Settings from Group.Unified AAD-SettingsTemplate and store information into $settings

     $Setting = Get-AzureADDirectorySetting | Where-Object { $_.DisplayName -eq "Group.Unified" }

     ##Can M365 Groups be created by everyone in the tenant?
     $EnableGroupCreationGlobally = $Setting.Values | Where-Object { $_.Name -eq "EnableGroupCreation" }


     ## Get Group-ID which is enabled to create M365Groups
     $GroupCreationAllowedGroupID = $Setting.Values | Where-Object { $_.Name -eq "GroupCreationAllowedGroupID" }

     $Group = Get-AzureADGroup | Where-Object { $_.ObjectId -eq $GroupCreationAllowedGroupID.Value }


     if ($EnableGroupCreationGlobally.Value -eq "false"){

          Write-Host "Members of the following AAD-Group can create M365-Groups:" -ForegroundColor Yellow
          Write-Host "-->  "  ($Group.DisplayName) "  <--" -ForegroundColor Green

     } else  {

          Write-Host ("Creation of M365-Groups is NOT restricted. All Users in your Azure AD can create M365-Groups.") -ForegroundColor Green
          Write-Host ("All Users in your Azure AD can create M365-Groups.") -ForegroundColor Green
     }

}


Function Opt2RestrictM365GrpCreation 
{
     Write-host 'Please Login to execute the Action (separate window). ' -ForegroundColor Black -BackgroundColor Yellow `n
     
     Connect-AzureAD

     Write-host 'Running script to allow M365-Group creation only for Members of the following AAD Security Group: ' -ForegroundColor Yellow -BackgroundColor DarkGreen `n

     $GroupName = Read-Host -Prompt 'Insert AAD Security Group Name'

     $AllowGroupCreation = $False
     
     Write-host 'Running script to allow M365-Group creation only for Members of the following AAD Security Group: ' -ForegroundColor Yellow -BackgroundColor DarkGreen `n
     Write-host $GroupName -ForegroundColor Yellow -BackgroundColor DarkGreen
          
     $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
     
     if(!$settingsObjectID){
         $template = Get-AzureADDirectorySettingTemplate | Where-object {$_.displayname -eq "group.unified"}
         $settingsCopy = $template.CreateDirectorySetting()
         New-AzureADDirectorySetting -DirectorySetting $settingsCopy
         $settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
     }
     
     $settingsCopy = Get-AzureADDirectorySetting -Id $settingsObjectID
     $settingsCopy["EnableGroupCreation"] = $AllowGroupCreation
     
     if($GroupName){
       $settingsCopy["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -SearchString $GroupName).objectid
     } 
     
     else {
     $settingsCopy["GroupCreationAllowedGroupId"] = $GroupName
     }
     
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settingsCopy
     
(Get-AzureADDirectorySetting -Id $settingsObjectID).Values

Write-Host ("All Members of your Tenant can now create M365-Groups. Watch your Governance! :-)") -ForegroundColor Green -BackgroundColor -black
Write-Host ""
}


Function Opt3EnableAllUsers 
{
   
     Write-Host 'Please login as Global Administrator in the prompted window...' -ForegroundColor Black -BackgroundColor Yellow `n

     $GroupName = ""
     $AllowGroupCreation = $True

     Connect-AzureAD
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

     Write-Host ("All Members of your Tenant can now create M365-Groups. Watch your Governance! :-)") -ForegroundColor Green -BackgroundColor White
     Write-Host ""
     }


     do
     {
          Show-Menu
          Write-Host ""
          $menuInput = Read-Host '-->What would you like to do? ('q' to quit)'
          switch ($menuInput){
               '1'  {
                    Clear-Host
                    Write-Host 'Option #1 selected. --> Verify if M365-Group creation is restricted.' `n
                    Opt1VerifyRestrictions
               } '2'{
                    Clear-Host
                    Write-Host 'Option #2 selected. --> Restrict M365-Group creation to a specific group in your AAD.' `n
                    Opt2RestrictM365GrpCreation
               } '3'{
                    Clear-Host
                    Write-Host 'Option 3 selected. --> Allow all users in your tenant to create M365-Groups.' `n
                    Opt3EnableAllUsers
               } 'q'{
                    return
               }
          }
          pause
}
until ($input -eq 'q')
