<#
                     _   _                        _
       ___   _ __   (_) | |_    ___         ___  | |__  
      / _ \ | '_ \  | | | __|  / _ \       / __| | '_ \ 
     |  __/ | | | | | | | |_  | (_) |  _  | (__  | | | |
      \___| |_| |_| |_|  \__|  \___/  (_)  \___| |_| |_|

      About Microsoft 365 and more... (https://enito.ch)

    .NOTES
    =========================NOTES START=========================
    Created on:       05. April 2022
    Updated on:       25. November 2023
    Created by:       Mirco Ingenito
    Filename:         orange-bongo-bomb.ps1

    .DESCRIPTION
    Verify, disable or enable restriction of M365-Group creation using Microsoft Graph.

    IMPORTANT: Existing security-group in AAD required for (Option 2) .
    =========================NOTES END=========================

#>

Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Beta.Groups

Function Show-Menu
{
    Clear-Host
    Write-Host "==============================================================" -ForegroundColor Blue -BackgroundColor Cyan
    Write-Host "| Manage 'who' can create Microsoft365-Groups in your Tenant |" -ForegroundColor Blue -BackgroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Blue -BackgroundColor Cyan
    Write-Host ""
    Write-Host ("IMPORTANT: Requirements to run the:") -ForegroundColor yellow
    Write-Host "------------------------------------" -ForegroundColor yellow
    Write-Host "--> PowerShell Core 7.4 and the following two Modules are required:" -ForegroundColor yellow
    Write-Host "    - Microsoft.Graph.Beta.Groups" -ForegroundColor yellow
    Write-Host "    - Microsoft.Graph.Beta.Identity.DirectoryManagement" -ForegroundColor yellow
    Write-Host "--> Script can only be executed by a Global Administrator in your Tenant" -ForegroundColor yellow
    Write-Host "--> You have to login for each Option you select with your credentials (Global Administrator required --> MFA)" -ForegroundColor yellow
    Write-Host "--> For Option 2 --> an existing Security Group in your Azure Active Directory" -ForegroundColor yellow
    Write-Host ""
    Write-Host ("Available Options:") -ForegroundColor Black -BackgroundColor Green
    Write-Host "------------------" 
    Write-Host "[ 1 ] Verify if restrictions are enabled... $a1" -ForegroundColor Green
    Write-Host "[ 2 ] Restrict M365-Group creation to a specific group in your AAD... $a2" -ForegroundColor Green
    Write-Host "[ 3 ] Allow all users in your tenant to create M365-Groups... (Microsoft default setting) $a3" -ForegroundColor Green
}

Function Connect-MgGraphWrapper
{
    Connect-MgGraph -Scopes "Directory.ReadWrite.All", "Group.Read.All" -noWelcome
}

Function Opt1VerifyRestrictions
{
    Write-host 'Please Login to execute the Action (separate window). ' -ForegroundColor Black -BackgroundColor Yellow `n
    Connect-MgGraphWrapper

    $Setting = Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq "Group.Unified" }

    $EnableGroupCreationGlobally = $Setting.Values | Where-Object { $_.Name -eq "EnableGroupCreation" }
    $GroupCreationAllowedGroupID = $Setting.Values | Where-Object { $_.Name -eq "GroupCreationAllowedGroupID" }

    $Group = Get-MgBetaGroup | Where-Object { $_.Id -eq $GroupCreationAllowedGroupID.Value }

    if ($EnableGroupCreationGlobally.Value -eq "false") {
        Write-Host "Members of the following AAD-Group can create M365-Groups:" -ForegroundColor Yellow
        Write-Host "-->  "  ($Group.DisplayName) "  <--" -ForegroundColor Green
    } else {
        Write-Host ("Creation of M365-Groups is NOT restricted. All Users in your Azure AD can create M365-Groups.") -ForegroundColor Green
    }
}

Function Opt2RestrictM365GrpCreation 
{
    Write-host 'Please Login to execute the Action (separate window). ' -ForegroundColor Black -BackgroundColor Yellow `n
    Connect-MgGraphWrapper

    $GroupName = Read-Host -Prompt 'Insert AAD Security Group Name'
    $AllowGroupCreation = $False

    Write-host 'Running script to allow M365-Group creation only for Members of the following AAD Security Group: ' -ForegroundColor Yellow -BackgroundColor DarkGreen `n
    Write-host $GroupName -ForegroundColor Yellow -BackgroundColor DarkGreen


    $settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Id

    if(!$settingsObjectID) {
        $params = @{
            templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
            values = @(
                @{
                    name = "EnableMSStandardBlockedWords"
                    value = "true"
                }
            )
        }

        New-MgBetaDirectorySetting -BodyParameter $params
        $settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Id
    }

    $groupId = (Get-MgBetaGroup -Filter "displayName eq '$GroupName'").Id

    $params = @{
        values = @(
            @{
                name = "EnableGroupCreation"
                value = $AllowGroupCreation
            },
            @{
                name = "GroupCreationAllowedGroupId"
                value = $groupId
            }
        )
    }

    Update-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID -BodyParameter $params
    (Get-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID).Values
}

Function Opt3EnableAllUsers 
{
    Write-Host 'Please login as Global Administrator in the prompted window...' -ForegroundColor Black -BackgroundColor Yellow `n
    Connect-MgGraphWrapper

    $AllowGroupCreation = $True
    $GroupName = ""

    $settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Id

    if(!$settingsObjectID) {
        $params = @{
            templateId = "62375ab9-6b52-47ed-826b-58e47e0e304b"
            values = @(
                @{
                    name = "EnableMSStandardBlockedWords"
                    value = "true"
                }
            )
        }

        New-MgBetaDirectorySetting -BodyParameter $params
        $settingsObjectID = (Get-MgBetaDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).Id
    }

    $params = @{
        values = @(
            @{
                name = "EnableGroupCreation"
                value = $AllowGroupCreation
            },
            @{
                name = "GroupCreationAllowedGroupId"
                value = $GroupName
            }
        )
    }

    Update-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID -BodyParameter $params
    (Get-MgBetaDirectorySetting -DirectorySettingId $settingsObjectID).Values
}

# Main loop
do
{
    Show-Menu
    $menuInput = Read-Host '-->What would you like to do? ('q' to quit)'
    switch ($menuInput){
        '1' {
            Clear-Host
            Write-Host 'Option #1 selected. --> Verify if M365-Group creation is restricted.' `n
            Opt1VerifyRestrictions
        }
        '2' {
            Clear-Host
            Write-Host 'Option #2 selected. --> Restrict M365-Group creation to a specific group in your AAD.' `n
            Opt2RestrictM365GrpCreation
        }
        '3' {
            Clear-Host
            Write-Host 'Option 3 selected. --> Allow all users in your tenant to create M365-Groups.' `n
            Opt3EnableAllUsers
        }
        'q' {
            return
        }
    }
    pause
}
until ($menuInput -eq 'q')
