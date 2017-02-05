'
' Here is how to set up your developer Client ID and Client Secret for OAuth2 authentication:
'
' 1. Log in to a gmail account
' 2. Go to: https://console.developers.google.com/project
' 3. Click 'Create Project'; in the 'New project' pop-up enter the Project name
' 4. Click 'Create'
' 5. Wait for the screen to refresh and show the Project Dashboard
' 6. Click 'API Manager' in the top-left-hand drop down menu, then click 'Credentials'
' 7. Click the 'OAuth Consent Screen' tab
' 8. Fill in the 'Product name' field then click 'Save'
' 9. Click the 'Credentials' tab then select 'OAuth client ID' under the 'Create Credentials' drop down button
' 10. On the 'Create client ID' screen, select an Application type of 'Other', Enter 'Roku' in the name field, then click 'Create'
' 11. Copy the key values: 'Here is your client ID' and 'Here is your client secret' into the strings below. Click OK
' 12. Double-check that the copied values exactly match the values on the Developer Console (e.g. you didn't miss a character off the end).
'
'******* UNCOMMENT THE FOLLOWING TWO LINES AND INSERT YOUR CLIENT ID AND CLIENT SECRET **********
Function getClientId()        As String : Return "<----- CLIENT ID HERE -------->" : End Function
Function getClientSecret()    As String : Return "<----- CLIENT SECRET HERE --------->" : End Function
