 param (
  [string]$listFullUrl, # Site URL
  [string]$tenantId, # Tenant ID for Microsoft Graph,
  [string]$aadClientId, # App ID for Microsoft Graph,
  [string]$aadClientSecret, # App secret for Microsoft Graph,
  [string]$grantedToAppId, # App ID of the application to which you want to grant permissions, usualy its the same as aadClientId,
  [string]$displayName, # Sites.Selected | Lists.SelectedOperations.Selected | ListItems.SelectedOperations.Selected | Files.SelectedOperations.Selected
  [string]$endPoint = "com", #defines the MS endpoint to use (Global - com, GCC High or DOD - us)
  [string]$permission # Read | Write | Manage | FullControl
 )
 
 try
 {
    # Extract site URL and list name from listFullUrl    
    $uri = [System.Uri]$listFullUrl
    $segments = $uri.AbsolutePath.Trim('/').Split('/')

    # Find the index of "Lists" or "lists" (case-insensitive)
    $listsIndex = -1
    for ($i = 0; $i -lt $segments.Length; $i++) {
        if ($segments[$i] -ieq "lists") {
            $listsIndex = $i
            break
        }
    }
    if ($listsIndex -lt 0 -or $listsIndex -ge $segments.Length - 1) {
        throw "Invalid SharePoint list URL: $listFullUrl"
    }

    # Site URL is everything up to (but not including) /Lists/ListName
    $sitePath = ($segments[0..($listsIndex - 1)] -join '/')
    $siteUrl = "$($uri.Scheme)://$($uri.Host)/$sitePath"

    # List name is the segment after "Lists"
    $listName = $segments[$listsIndex + 1]

    # Define scopes and login URL
    $graphUrl = "https://graph.microsoft.$endPoint"
    $scope = "$graphUrl/.default"
    $loginURL = "https://login.microsoftonline.$endPoint/$tenantId/oauth2/v2.0/token"

    # Prepare body for token request
    $body = @{
    grant_type    = "client_credentials"
    client_id     = $aadClientId
    client_secret = $aadClientSecret
    scope         = $scope
    }

    # Get the token
    $tokenResponse = Invoke-RestMethod -Method Post -Uri $loginURL -Body $body
    $token = $tokenResponse.access_token

    # Construct site id for Graph
    $uri = [System.Uri]$siteUrl
    $siteIdForGraph = "$($uri.Authority):$($uri.AbsolutePath)"



    # Prepare headers for Graph API requests
    $headerParams = @{
    'Authorization' = "Bearer $token"
    }

    # Get site information
    $response = Invoke-RestMethod -Method Get -Headers $headerParams -ContentType "application/json" -Uri "$graphUrl/v1.0/sites/$siteIdForGraph"
    # $response.id is in the format 'hostname,siteId,webId'
    # Split by comma and use the second value (siteId)
    $siteId = $response.id.Split(',')[1]


    # Get list information
    $listApiUrl = "$graphUrl/v1.0/sites/$siteId/lists?`$filter=displayName eq '$listName'"
    $listInfo = Invoke-RestMethod -Method Get -Uri $listApiUrl -Headers @{ 
        'Accept' = 'application/json'
        'Authorization' = "Bearer $token" 
    }

    if ($listInfo.value.Count -eq 0) {
        throw "List '$listName' not found at site '$siteUrl'"
    }
    $listid = $listInfo.value[0].id




  # Prepare body for permission request
  $body = @{
   roles = @($permission)
   grantedTo = @{
        application = @{
            id = $grantedToAppId
        }
    }
  } | ConvertTo-Json -Depth 3


  Write-Host "SiteID:"$siteId
  Write-Host "ListID:"$listid
  
  # Grant permissions
  $r = Invoke-RestMethod -Method Post -Headers $headerParams -ContentType "application/json" -Uri "$graphUrl/beta/sites/$siteId/lists/$listid/permissions" -Body $body
  Write-Host "Successfully granted permission [$($r.roles[0])] for app [$($r.grantedTo[0].application.id)] for the list - $listFullUrl"

 }
 catch [System.SystemException]
 {
  Write-Host "Error!" -ForegroundColor red
  Write-Host $_ -ForegroundColor red
 }