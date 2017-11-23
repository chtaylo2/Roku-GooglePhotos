
sub init()
    m.buttongroup   = m.top.findNode("buttonGroup")
    m.Row1          = m.top.findNode("Row1")
    m.Row2          = m.top.findNode("Row2")
    m.Row3          = m.top.findNode("Row3")
    m.Row4          = m.top.findNode("Row4")
    m.Row5          = m.top.findNode("Row5")
    m.LoginTimer    = m.top.findNode("LoginTimer")
    
    m.Row4.font.size = 45

    m.buttongroup.buttons = [ "Get a new code", "About Channel" ]
    
    m.UriHandler = createObject("roSGNode","UrlHandler")
    m.UriHandler.observeField("gen_token_response","onNewToken")
    m.LoginTimer.observeField("fire","onCheckAuth")

    'm.Button.observeField("buttonSelected", "onButtonPress")
    m.buttongroup.setFocus(true)
    
    'Load common variables
    loadCommon()
    
    'Kick off token generation
    loadReg()
    doGenerateToken()
    
end sub

sub doGenerateToken()
    print "Registration.brs [doGenerateToken]"

    params = "client_id="        + m.clientId
    params = params + "&scope="  + m.oauth_scope

    makeRequest({}, m.oauth_prefix+"/device/code", "POST", params, 0)
end sub


sub onNewToken(event as object)
    print "Registration.brs [onNewToken]"
  
    tokenData = event.getData()
    
    json = ParseJson(tokenData.content)
    if json = invalid
        m.errorMsg = "Unable to parse Json response"
        m.oa.status = 1
    else if type(json) <> "roAssociativeArray"
        m.errorMsg = "Json response is not an associative array"
        m.oa.status = 1
    else if json.DoesExist("error")
        m.errorMsg = "Json error response: " + json.error
        m.oa.status = 1
    else
        m.userCode              = getString(json,"user_code")
        m.deviceCode            = getString(json,"device_code")
        m.verificationUrl       = getString(json,"verification_url")
        m.pollExpiresIn         = getInteger(json,"expires_in")
        m.interval              = getInteger(json,"interval")
        if m.userCode           = ""    then m.errorMsg = "Missing user_code"           : m.oa.status = 1
        if m.deviceCode         = ""    then m.errorMsg = "Missing device_code"         : m.oa.status = 1
        if m.verificationUrl    = ""    then m.errorMsg = "Missing verification_url"    : m.oa.status = 1
        if m.pollExpiresIn      = 0     then m.errorMsg = "Missing expires_in"          : m.oa.status = 1
        if m.interval           = 0     then m.errorMsg = "Missing interval"            : m.oa.status = 1    
    end if
  
    m.Row2.text = m.verificationUrl
    m.Row4.text = m.userCode
    
    m.LoginTimer.repeat = true
    m.LoginTimer.control = "start"
end sub

sub onCheckAuth(event as object)
    print "Registration.brs [onCheckAuth]"
    status = -1   ' 0 => Finished (got tokens), < 0 => Retry needed, > 0 => fatal error
    
    pollData = m.UriHandler.poll_token_response
        
    if pollData <> invalid
        json = ParseJson(pollData.content)
        if json = invalid
            m.errorMsg = "Unable to parse Json response"
            status = 1
        else if type(json) <> "roAssociativeArray"
            m.errorMsg = "Json response is not an associative array"
            status = -1
        else if json.DoesExist("error")
            if json.error = "authorization_pending"
                status = -1    ' Retry
            else if json.error = "slow_down"
                m.LoginTimer.duration = m.LoginTimer.duration + 2        ' Increase polling interval
                status = -1    ' Retry
            else
                m.errorMsg = "Json error response: " + json.error
                status = 1
            end if
        else
            'Stop the polling
            status = 0
            
            ' We have our tokens    
            m.accessToken.Push(getString(json,"access_token"))
            m.refreshToken.Push(getString(json,"refresh_token"))
            m.userInfoName.Push("Test User")
            m.userInfoEmail.Push("some_account@gmail.com")
            m.userInfoPhoto.Push("test")
            m.tokenType          = getString(json,"token_type")
            m.tokenExpiresIn     = getInteger(json,"expires_in")

            'Query User info
            'status = m.RequestUserInfo(m.accessToken.Count()-1, false)

            if m.tokenType       = "" then m.errorMsg = "Missing token_type"      : status = 1
            if m.tokenExpiresIn  = 0  then m.errorMsg = "Missing expires_in"      : status = 1

            'Save cached values to registry
            saveReg()
            
            m.Row1.text = ""  
            m.Row2.text = "Successfully Linked Account!"
            m.Row3.text = "You have successfully linked this Roku device to your Google Photos account"
            m.Row4.text = ""
            m.Row5.text = ""
                
        end if   
    end if
    
    if status = 0 then
        m.LoginTimer.repeat = false
        m.LoginTimer.control = "stop"
    else
        params = "client_id="                 + m.clientId
        params = params + "&client_secret="   + m.clientSecret
        params = params + "&code="            + m.deviceCode
        params = params + "&grant_type="      + "http://oauth.net/grant_type/device/1.0"
    
        makeRequest({}, m.oauth_prefix+"/token", "POST", params, 1)

        m.LoginTimer.repeat = true
        m.LoginTimer.control = "start"
    end if
end sub


''NOT USED YET
sub onButtonPress(event as object)
  print "onButtonPress"
  if m.button.text <> "Unlink The Device"
    makeRequest({}, m.gen, "GET", 0)
    m.LoginTimer.repeat = true
    m.LoginTimer.control = "start"
  else
    makeRequest({}, m.dis, "GET", 2)
    m.LoginTimer.repeat = true
    m.LoginTimer.control = "start"
  end if
end sub


'******************************************************************************
'**
'** Extract a string from an associative array returned by ParseJson
'** Return the default value if the field is missing, invalid or the wrong type
'**
'******************************************************************************
Function getString(json As Dynamic,fieldName As String,defaultValue="" As String) As String
    returnValue = defaultValue
    if json <> Invalid
        if type(json) = "roAssociativeArray" or GetInterface(json,"ifAssociativeArray")
            fieldValue = json.LookupCI(fieldName)
            if fieldValue <> Invalid
                if type(fieldValue) = "roString" or type(fieldValue) = "String" or GetInterface(fieldValue,"ifString") <> Invalid
                    returnValue = fieldValue
                end if
            end if
        end if
    end if
    return returnValue
End Function


'******************************************************************************
'**
'** Extract an integer from an associative array returned by ParseJson
'** Return the default value if the field is missing, invalid or the wrong type
'**
'******************************************************************************
Function getInteger(json As Dynamic,fieldName As String,defaultValue=0 As Integer) As Integer
    returnValue = defaultValue
    if json <> Invalid
        if type(json) = "roAssociativeArray" or GetInterface(json,"ifAssociativeArray")
            fieldValue = json.LookupCI(fieldName)
            if fieldValue <> Invalid
                if type(fieldValue) = "roInteger" or type(fieldValue) = "Integer" or type(fieldValue) = "roInt" or GetInterface(fieldValue,"ifInt") <> Invalid
                    returnValue = fieldValue
                end if
            end if
        end if
    end if
    return returnValue
End Function
