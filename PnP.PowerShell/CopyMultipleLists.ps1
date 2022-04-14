<#	
	.NOTES
	=========================NOTES START=========================
	 Created on:   	16. April 2022
	 Created by:   	Mirco Ingenito
	 Organization: 	https://enito.ch
	 Filename:     	CopyMultipleLists.ps1

	=========================DESCRIPTION=========================
	.DESCRIPTION
	Verify, disable or enable restriction of M365-Group creation.
    
    IMPORTANT: Existing security-group in AAD required for (Option 2) .
   	=========================NOTES END=========================

#>


## Connect to Source Site
Connect-PnPOnline -Url https://enito365.sharepoint.com/sites/OrderProcessAutomation/ -Interactive

## Create the Template (Due to a lookup-field in the main list, we have to export all dependent lists too. (4 in Total)) 
Get-PnPSiteTemplate -Out Lists.xml -ListsToExtract “opa_NewOrder”, “opa_OrderList”, "opa_ItemPriceVM", "opa_ItemPriceDisk" -Handlers Lists

## Get the List Data for each list (can be skipped if you don't need the list-content)
<#
Add-PnPDataRowsToSiteTemplate -Path Lists.xml -List “[LIST 1]”
Add-PnPDataRowsToSiteTemplate -Path Lists.xml -List “[LIST 2]”
Add-PnPDataRowsToSiteTemplate -Path Lists.xml -List “[LIST 3]”
Add-PnPDataRowsToSiteTemplate -Path Lists.xml -List “[LIST n]”
##>

## Connect to Target Site
Connect-PnPOnline -Url https://ingenitecgroup.sharepoint.com/sites/Spielwiese/ -Interactive

## Apply the Template
Invoke-PnPSiteTemplate -Path Lists.xml