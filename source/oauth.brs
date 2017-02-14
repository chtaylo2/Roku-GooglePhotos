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
    this.oauth_scope             = "https://picasaweb.google.com/data https://www.googleapis.com/auth/userinfo.email"

    this.clientId                = clientId
    this.clientSecret            = clientSecret

    this.RequestUserCode         = oauth_request_user_code
    this.PollForTokens           = oauth_poll_for_tokens
    this.accessTokenIndex        = oauth_access_token_index
    this.RefreshTokens           = oauth_refresh_tokens
    this.RequestUserInfo         = oauth_request_userinfo

    this.count                   = oauth_count
    this.sign                    = oauth_sign
    this.section                 = "GooglePhotos-Auth"
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
    this.currentAccessTokenInd   = 0
    this.tokenType               = ""
    this.usersRegistered         = 0    ' How many users we have linked to Roku device

    this.pollDelay               = 0    ' Amount of time to add to poll interval if Google thinks we are polling too fast
    this.errorMsg                = ""

    this.items.push("accessToken")
    this.items.push("refreshToken")
    this.items.push("userInfoName")
    this.items.push("userInfoEmail")
    this.items.push("userInfoPhoto")
    
    this.load()        ' Load access token and refresh token from the registry
    this.save()

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

    m.deviceCode                 = ""
    m.userCode                   = ""
    m.verificationUrl            = ""
    m.pollExpiresIn              = 0
    m.interval                   = 0

    m.pollDelay                  = 0

    http = NewHttp(m.oauth_prefix+"/device/code",invalid,"POST")
    http.AddHeader("Content-Type","application/x-www-form-URLEncoded")

    params = ""
    params = params + "client_id="    + URLEncode(m.clientId)
    params = params + "&scope="       + URLEncode(m.oauth_scope)

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

    oa = Oauth()

    status              = 0    ' 0 => Finished (got tokens), < 0 => Retry needed, > 0 => fatal error
    m.errorMsg          = ""
   
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
            m.accessToken.Push(getString(json,"access_token"))
            m.refreshToken.Push(getString(json,"refresh_token"))
            m.tokenType          = getString(json,"token_type")
            m.tokenExpiresIn     = getInteger(json,"expires_in")

            'Query User info
            status = m.RequestUserInfo(m.accessToken.Count()-1, false)

            if m.tokenType       = "" then m.errorMsg = "Missing token_type"      : status = 1
            if m.tokenExpiresIn  = 0  then m.errorMsg = "Missing expires_in"      : status = 1
        end if
    endif
    
    return status
End Function

'**************************************************************************************
'**
'** Pull user details to store
'**
'**************************************************************************************
Function oauth_request_userinfo(userIndex As Integer, isrefresh=false As Boolean) As Integer

    oa = Oauth()
    
    status                       = 0        ' 0 => Success, <> 0 => failed
    m.errorMsg                   = ""

    http = NewHttp("https://www.googleapis.com/oauth2/v3/userinfo?access_token=" +  URLEncode(m.accessToken[userIndex]))

    rsp = http.getToStringWithTimeout(10)

    print "oauth_request_userinfo: http failure = "; http.GetFailureReason()
    print "oauth_request_userinfo: http response = "; rsp

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
            infoName  = getString(json,"name")
            infoEmail = getString(json,"email")
            infoPhoto = getString(json,"picture")

            'Special Charactor management
            infoName  = infoName.Replace(".", "")
            infoName  = strReplaceSpecial(infoName)
            infoEmail = strReplaceSpecial(infoEmail)

            if infoName  = "" then infoName  = "Google Photos User"
            if infoEmail = "" then infoName  = "No email on file"
            if infoPhoto = "" then infoPhoto = "pkg:/images/userdefault.png"
            
            if isrefresh = true then
                m.userInfoName[m.currentAccessTokenInd]  = infoName
                m.userInfoEmail[m.currentAccessTokenInd] = infoEmail
                m.userInfoPhoto[m.currentAccessTokenInd] = infoPhoto
            else
            
                if infoEmail <> "No email on file" then
                    for i = 0 to m.userInfoEmail.Count()-1
                        if m.userInfoEmail[i] = infoEmail then
                            m.accessToken.Pop()
                            m.refreshToken.Pop()
                            ShowDialog1Button("Notice", "Account '"+infoEmail+"' already linked to device", "OK")
                            return 0
                        end if
                    end for
                end if
            
                m.userInfoName.Push(infoName)
                m.userInfoEmail.Push(infoEmail)
                m.userInfoPhoto.Push(infoPhoto)
            end if
            
            if infoEmail = "" then m.errorMsg = "Missing User Data (Email)" : status = 1
            if infoName  = "" then m.errorMsg = "Missing User Data (Name)" : status = 1
            if infoPhoto = "" then m.errorMsg = "Missing User Data (Photo" : status = 1
        end if
    endif

    return status
End Function

'**************************************************************************************
'**
'** Return the OAuth2 access token index to use with an API request
'**
'**************************************************************************************
Function oauth_access_token_index() As Integer
    return m.currentAccessTokenInd
End Function

'**************************************************************************************
'**
'** Send an OAuth2 request for a new access and refresh token after a token has expired
'**
'**************************************************************************************
Function oauth_refresh_tokens() As Integer

    oa = Oauth()

    status        = 0        ' 0 => Success, <> 0 => failed
    m.errorMsg    = ""

    http = NewHttp(m.oauth_prefix+"/token",invalid,"POST")
    http.AddHeader("Content-Type","application/x-www-form-URLEncoded")

    params = ""
    params = params + "client_id="         + URLEncode(m.clientId)
    params = params + "&client_secret="    + URLEncode(m.clientSecret)
    params = params + "&refresh_token="    + URLEncode(m.refreshToken[m.currentAccessTokenInd])
    params = params + "&grant_type="       + URLEncode("refresh_token")

    rsp = http.postFromStringWithTimeout(params, 10)

    print "oauth_refresh_tokens: index: "; m.currentRefreshTokenInd
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
            
            m.accessToken[m.currentAccessTokenInd]  = getString(json,"access_token")
            m.tokenType                             = getString(json,"token_type")
            m.tokenExpiresIn                        = getInteger(json,"expires_in")
            refreshToken                            = getString(json,"refresh_token")
            if refreshToken <> ""
                m.refreshToken[m.currentAccessTokenInd] = refreshToken
            end if

            'Query User info - Refresh
            if m.userInfoName[m.currentAccessTokenInd]="Legacy User" then
                status = 0
            else
                status = m.RequestUserInfo(m.currentAccessTokenInd, true)
            end if

            if m.accessToken[m.currentAccessTokenInd]  = ""    then m.errorMsg = "Missing access_token"    : status = 1
            if m.tokenType                             = ""    then m.errorMsg = "Missing token_type"      : status = 1
            if m.tokenExpiresIn                        = 0     then m.errorMsg = "Missing expires_in"      : status = 1
        end if
    end if

    return status
End Function

'*********************************************************
'**
'** adds authorization token to an API request
'**
'*********************************************************
Function oauth_sign(http As Object, userIndex As Integer)

    ' Save our current selection
    m.currentAccessTokenInd = userIndex
    
    if m.accessToken[m.currentAccessTokenInd] <> ""
        http.AddHeader("Authorization", "Bearer " + m.accessToken[m.currentAccessTokenInd])
        print "Signing http: "; m.accessToken[m.currentAccessTokenInd]
    end if

End Function

'*********************************************************
'**
'** Count number of user tokens we have
'**
'*********************************************************
Function oauth_count()
    
    for each item in m.items
        if m.accessToken.Count() <> m.[item].Count() then
            print "accessToken / "; item; " counts do not match"
            return invalid
        end if
    end for
    
    return m.accessToken.Count()

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
