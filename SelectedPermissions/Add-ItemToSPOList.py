import requests
import json
from msal import ConfidentialClientApplication

# Azure AD app registration details
CLIENT_ID = ''
CLIENT_SECRET = ''
TENANT_ID = ''

# SharePoint and list details
SITE_ID = ''  # get Site ID from Set-SelectedPermissionsToListViaApp.ps1 output
LIST_ID = ''  # get List ID from Set-SelectedPermissionsToListViaApp.ps1 output

# Item to add
item_fields = {
    "Title": "Test Title",
    "Details": "Test Details",
    # Add other fields as needed
}

# Get access token
authority = f"https://login.microsoftonline.com/{TENANT_ID}"
app = ConfidentialClientApplication(
    CLIENT_ID,
    authority=authority,
    client_credential=CLIENT_SECRET
)
scopes = ["https://graph.microsoft.com/.default"]
result = app.acquire_token_for_client(scopes=scopes)
if "access_token" not in result:
    raise Exception("Could not obtain access token: " + json.dumps(result, indent=2))

access_token = result["access_token"]

# Add item to SharePoint list via Microsoft Graph
url = f"https://graph.microsoft.com/v1.0/sites/{SITE_ID}/lists/{LIST_ID}/items"
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}
payload = {
    "fields": item_fields
}

response = requests.post(url, headers=headers, json=payload)
if response.status_code == 201:
    print("Item added successfully:", response.json())
else:
    print("Error adding item:", response.status_code, response.text)