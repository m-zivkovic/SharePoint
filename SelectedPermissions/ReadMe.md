In Entra ID Create 2 app registrations.

App no. 1 - use this App to grant other apps selected permisions.

App no. 2 - to use in code and that will have granted permissions.

For App no. 1 add Graph API permission Type:Application, Permission: Sites.FullControl.All

For App no. 2 add Graph API permission Type:Application, Permission: Lists.SelectedOperations.Selected


Set permission to App no. 2 using the Set-SelectedPermissionsToListViaApp.ps1.

Set-SelectedPermissionsToListViaApp.ps1 -listFullUrl "FULL URL LINK TO THE LIST" -tenantId "TENANT ID" -aadClientId "APP NO. 1 ID" -aadClientSecret "APP NO. 1 SECRET" -grantedToAppId "APP NO. 2 ID" -displayName "APP NO. 2 DISPLAY NAME" -permission "write"

From the output of Set-SelectedPermissionsToListViaApp.ps1, get the Site ID and List ID.

Use the Add-ItemToSPOList.py example to Add item to Sharepoint Online List.
