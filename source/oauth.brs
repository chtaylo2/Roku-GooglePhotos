'
' Use OAuth2 For Devices as described in:
'     https://developers.google.com/accounts/docs/OAuth2ForDevices
' The Client ID and Client Secret are contained in private.brs
'
Function Oauth() As Object
    return  m.oa
End Function

'*********************************************************
'**
'** Set up an OAuth object
'**
'*********************************************************
Function InitOauth(clientId As String, clientSecret As String) As Object
    print "clientId: "; clientId; " clientSecret: "; clientSecret

    this = CreateObject("roAssociativeArray")

    this.oauth_prefix            = "https://accounts.google.com/o/oauth2" 

    this.clientId                = clientId
    this.clientSecret            = clientSecret

    this.RequestUserCode         = oauth_request_user_code
    this.PollForTokens           = oauth_poll_for_tokens
    this.CurrentAccessToken      = oauth_current_access_token
    this.RefreshTokens           = oauth_refresh_tokens

    this.sign                    = oauth_sign
    this.section                 = "Picasa-Auth"
    this.items                   = CreateObject("roList")
    this.load                    = loadReg    ' from regScreen.brs
    this.save                    = saveReg    ' from regScreen.brs
    this.erase                   = eraseReg   ' from regScreen.brs
    this.linked                  = definedReg ' from regScreen.brs
    this.dump                    = dumpReg    ' from regScreen.brs

    this.deviceCode              = ""
    this.userCode                = ""
    this.verificationUrl         = ""
    this.pollExpiresIn           = 0
    this.tokenExpiresIn          = 0
    this.interval                = 0
    this.accessToken             = ""
    this.tokenType               = ""
    this.refreshToken            = ""

    this.pollDelay               = 0    ' Amount of time to add to poll interval if Google thinks we are polling too fast

    this.errorMsg                = ""

    this.items.push("accessToken")
    this.items.push("refreshToken")
    
    this.load()        ' Load access token and refresh token from the registry
    
    return this
End Function

'**************************************************************************************
'**
'** Send an OAuth2 request for a user's code
'**
'**************************************************************************************
Function oauth_request_user_code() As Integer
    status                       = 0        ' 0 => Success, <> 0 => failed
    m.errorMsg                   = ""

    m.accessToken                = ""
    m.refreshToken               = ""

    m.deviceCode                 = ""
    m.userCode                   = ""
    m.verificationUrl            = ""
    m.pollExpiresIn              = 0
    m.interval                   = 0

    m.pollDelay                  = 0

    picasa = LoadPicasa()

    http = NewHttp(m.oauth_prefix+"/device/code",invalid,"POST")
    http.AddHeader("Content-Type","application/x-www-form-URLEncoded")

    params = ""
    params = params + "client_id="    + URLEncode(m.clientId)
    params = params + "&scope="       + URLEncode(picasa.scope)

    rsp = http.postFromStringWithTimeout(params, 10)

    print "oauth_request_user_code: http failure = "; http.GetFailureReason()
    print "oauth_request_user_code: http response = "; rsp

    if http.GetResponseCode () <> 200
        m.errorMsg = http.GetFailureReason()
        status = 1
    else
        json = ParseJson(rsp)
        if json = invalid
            m.errorMsg = "Unable to parse Json response"
            status = 1
        else if type(json) <> "roAssociativeArray"
            m.errorMsg = "Json response is not an associative array"
            status = 1
        else if json.DoesExist("error")
            m.errorMsg = "Json error response: " + json.error
            status = 1
        else
            m.userCode              = getString(json,"user_code")
            m.deviceCode            = getString(json,"device_code")
            m.verificationUrl       = getString(json,"verification_url")
            m.pollExpiresIn         = getInteger(json,"expires_in")
            m.interval              = getInteger(json,"interval")
            if m.userCode           = ""    then m.errorMsg = "Missing user_code"           : status = 1
            if m.deviceCode         = ""    then m.errorMsg = "Missing device_code"         : status = 1
            if m.verificationUrl    = ""    then m.errorMsg = "Missing verification_url"    : status = 1
            if m.pollExpiresIn      = 0     then m.errorMsg = "Missing expires_in"          : status = 1
            if m.interval           = 0     then m.errorMsg = "Missing interval"            : status = 1    
        end if
    endif

    return status
End Function

'**************************************************************************************
'**
'** Send an OAuth2 poll request for access and refresh tokens
'**
'**************************************************************************************
Function oauth_poll_for_tokens() As Integer
    status              = 0    ' 0 => Finished (got tokens), < 0 => Retry needed, > 0 => fatal error
    m.errorMsg          = ""

    m.accessToken       = ""
    m.tokenType         = ""
    m.tokenExpiresIn    = 0
    m.refreshToken      = ""

    http = NewHttp(m.oauth_prefix+"/token",invalid,"POST")
    http.AddHeader("Content-Type","application/x-www-form-URLEncoded")
    
    params = ""
    params = params + "client_id="        + URLEncode(m.clientId)
    params = params + "&client_secret="   + URLEncode(m.clientSecret)
    params = params + "&code="            + URLEncode(m.deviceCode)
    params = params + "&grant_type="      + URLEncode("http://oauth.net/grant_type/device/1.0")

    rsp = http.postFromStringWithTimeout(params, 10)

    print "oauth_poll_for_tokens: http failure = "; http.GetFailureReason()
    print "oauth_poll_for_tokens: http response = "; rsp

    if http.GetResponseCode () <> 200
        m.errorMsg = http.GetFailureReason()
        status = 1
    else
        json = ParseJson(rsp)
        if json = invalid
            m.errorMsg = "Unable to parse Json response"
            status = 1
        else if type(json) <> "roAssociativeArray"
            m.errorMsg = "Json response is not an associative array"
            status = 1
        else if json.DoesExist("error")
            print "oauth_poll_for_tokens: Json error response: "; json.error
            if json.error = "authorization_pending"
                status = -1    ' Retry
            else if json.error = "slow_down"
                m.pollDelay = m.pollDelay + 2        ' Increase polling interval
                status = -1    ' Retry
            else
                m.errorMsg = "Json error response: " + json.error
                status = 1
            end if
        else
            ' We have our tokens
            m.accessToken        = getString(json,"access_token")
            m.tokenType          = getString(json,"token_type")
            m.tokenExpiresIn     = getInteger(json,"expires_in")
            m.refreshToken       = getString(json,"refresh_token")
            if m.accessToken     = ""    then m.errorMsg = "Missing access_token"    : status = 1
            if m.tokenType       = ""    then m.errorMsg = "Missing token_type"      : status = 1
            if m.tokenExpiresIn  = 0     then m.errorMsg = "Missing expires_in"      : status = 1
            if m.refreshToken    = ""    then m.errorMsg = "Missing refresh_token"   : status = 1
        end if
    endif
    
    return status
End Function

'**************************************************************************************
'**
'** Return the OAuth2 access token to use with an API request
'**
'**************************************************************************************
Function oauth_current_access_token() As String
    return m.accessToken
End Function

'**************************************************************************************
'**
'** Send an OAuth2 request for a new access and refresh token after a token has expired
'**
'**************************************************************************************
Function oauth_refresh_tokens() As Integer
    status        = 0        ' 0 => Success, <> 0 => failed
    m.errorMsg    = ""

    http = NewHttp(m.oauth_prefix+"/token",invalid,"POST")
    http.AddHeader("Content-Type","application/x-www-form-URLEncoded")

    params = ""
    params = params + "client_id="         + URLEncode(m.clientId)
    params = params + "&client_secret="    + URLEncode(m.clientSecret)
    params = params + "&refresh_token="    + URLEncode(m.refreshToken)
    params = params + "&grant_type="       + URLEncode("refresh_token")

    rsp = http.postFromStringWithTimeout(params, 10)

    print "oauth_refresh_tokens: params: "; params; ". http failure = "; http.GetFailureReason()
    print "oauth_refresh_tokens: http response = "; rsp

    if http.GetResponseCode () <> 200
        m.errorMsg = http.GetFailureReason()
        status = 1
    else
        json = ParseJson(rsp)
        if json = invalid
            m.errorMsg = "Unable to parse Json response"
            status = 1
        else if type(json) <> "roAssociativeArray"
            m.errorMsg = "Json response is not an associative array"
            status = 1
        else if json.DoesExist("error")
            m.errorMsg = "Json error response: " + json.error
            status = 1
        else
			' Extract data from the response. Note, the refresh_token is optional
            m.accessToken        = getString(json,"access_token")
            m.tokenType          = getString(json,"token_type")
            m.tokenExpiresIn     = getInteger(json,"expires_in")
            refreshToken		 = getString(json,"refresh_token")
			if refreshToken <> ""
				m.refreshToken   = refreshToken
			end if

            if m.accessToken     = ""    then m.errorMsg = "Missing access_token"    : status = 1
            if m.tokenType       = ""    then m.errorMsg = "Missing token_type"      : status = 1
            if m.tokenExpiresIn  = 0     then m.errorMsg = "Missing expires_in"      : status = 1
        end if
    end if

    return status
End Function

'*********************************************************
'**
'** adds authorization token to an API request
'**
'*********************************************************
Function oauth_sign(http As Object, protected=true As Boolean)

    if protected and m.accessToken <> ""
        http.AddHeader("Authorization", "Bearer " + m.accessToken)
    end if

End Function

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