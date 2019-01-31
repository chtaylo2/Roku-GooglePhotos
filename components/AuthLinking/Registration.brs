'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    m.buttongroup       = m.top.findNode("buttonGroup")
    m.Row1              = m.top.findNode("Row1")
    m.Row2              = m.top.findNode("Row2")
    m.Row3              = m.top.findNode("Row3")
    m.Row4              = m.top.findNode("Row4")
    m.Row5              = m.top.findNode("Row5")
    m.LoginTimer        = m.top.findNode("LoginTimer")
    m.stopScanning      = m.top.findNode("stopScanning")
    m.showRegistration  = m.top.findNode("showRegistration")
    m.noticeDialog      = m.top.findNode("noticeDialog")
    
    m.Row4.font.size = 65
    
    m.UriHandler = createObject("roSGNode","Content UrlHandler")
    m.UriHandler.observeField("gen_token_response","onNewToken")
    m.LoginTimer.observeField("fire","onCheckAuth")
    m.stopScanning.observeField("fire","onStopScanningTrigger")

    m.buttongroup.buttons = [ "Get a new code", "About Channel" ]
    m.buttongroup.setFocus(true)
    m.buttongroup.observeField("buttonSelected","onButtonPress")
    
    'Load common variables
    loadCommon()

    'Load privlanged variables
    loadPrivlanged()
   
    'Kick off token generation
    loadReg()
    doGenerateToken()
    
End Sub


Sub doGenerateToken()
    print "Registration.brs [doGenerateToken]"

    params = "client_id="        + m.clientId
    params = params + "&scope="  + m.oauth_scope

    makeRequest({}, m.register_prefix+"/cgi-bin/device/code", "POST", params, 4, [])
End Sub


Sub doQueryUserInfo()
    print "Registration.brs [doQueryUserInfo]"

    m.UriHandler.observeField("userinfo_response","onStoreUser")
    userIndex = m.accessToken.Count()-1
    makeRequest({}, "https://www.googleapis.com/oauth2/v3/userinfo?access_token="+m.accessToken[userIndex], "GET", "", 6, [])
End Sub


Sub onNewToken(event as object)
    print "Registration.brs [onNewToken]"

    errorMsg = ""
    tokenData = event.getData()

    if tokenData.code <> 200
        errorMsg = "An Error Occurred in 'onNewToken'. Code: "+(tokenData.code).toStr()+" - " +tokenData.error
    else
        json = ParseJson(tokenData.content)
        if json = invalid
            errorMsg = "Unable to parse Json response: onNewToken"
        else if type(json) <> "roAssociativeArray"
            errorMsg = "Json response is not an associative array: onNewToken"
        else if json.DoesExist("error")
            errorMsg = "Json error response: [onNewToken] " + json.error
        else
            m.userCode              = getString(json,"user_code")
            m.deviceCode            = getString(json,"device_code")
            m.verificationUrl       = getString(json,"verification_url")
            m.pollExpiresIn         = getInteger(json,"expires_in")
            m.interval              = getInteger(json,"interval")
            
            m.Row2.text = m.verificationUrl
            m.Row4.text = m.userCode
            
            m.LoginTimer.repeat     = true
            m.LoginTimer.control    = "start"
            m.stopScanning.control  = "start"
        end if
    end if
    
    if errorMsg<>"" then
        'ShowNotice
        m.noticeDialog.visible = true
        buttons =  [ "RETRY" ]
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
    end if   
    
End Sub


Sub onCheckAuth(event as object)
    print "Registration.brs [onCheckAuth]"
    status = -1   ' 0 => Finished (got tokens), < 0 => Retry needed, > 0 => fatal error
        
    errorMsg = ""
    pollData = m.UriHandler.poll_token_response
    
    if pollData <> invalid
        if pollData.code <> 200
            errorMsg = "An Error Occurred in 'onCheckAuth'. Code: "+(pollData.code).toStr()+" - " +pollData.error
        else
            json = ParseJson(pollData.content)
            if json = invalid
                errorMsg = "Unable to parse Json response: onCheckAuth"
                status = 1
            else if type(json) <> "roAssociativeArray"
                errorMsg = "Json response is not an associative array: onCheckAuth"
                status = -1
            else if json.DoesExist("error")
                if json.error = "authorization_pending"
                    status = -1    ' Retry
                else if json.error = "slow_down"
                    m.LoginTimer.duration = m.LoginTimer.duration + 2        ' Increase polling interval
                    status = -1    ' Retry
                else
                    errorMsg = "Json error response: [onCheckAuth] " + json.error
                    status = 1
                end if
            else
                'Stop the polling
                status = 0
                
                'Stop watching for field changes
                m.UriHandler.unobserveField("gen_token_response")
                m.LoginTimer.unobserveField("fire")
                
                ' We have our tokens    
                m.accessToken.Push(getString(json,"access_token"))
                m.refreshToken.Push(getString(json,"refresh_token"))
                m.versionToken.Push("v3token")
                m.tokenType          = getString(json,"token_type")
                m.tokenExpiresIn     = getInteger(json,"expires_in")
    
                'Query User info
                doQueryUserInfo()
                
            end if
        end if
    end if
    
    if errorMsg<>"" then
        'ShowNotice
        m.noticeDialog.visible = true
        buttons =  [ "RETRY" ]
        m.noticeDialog.message = errorMsg
        m.noticeDialog.buttons = buttons
        m.noticeDialog.setFocus(true)
        m.noticeDialog.observeField("buttonSelected","noticeClose")
        
        m.UriHandler.unobserveField("gen_token_response")
        m.LoginTimer.unobserveField("fire")
    end if    
    
    if status = 0 then
        m.LoginTimer.repeat = false
        m.LoginTimer.control = "stop"
    else
        params = "client_id="                 + m.clientId
        params = params + "&code="            + m.deviceCode
    
        makeRequest({}, m.register_prefix+"/cgi-bin/device/token", "POST", params, 5, [])

        m.LoginTimer.repeat = true
        m.LoginTimer.control = "start"
    end if
End Sub


Sub onStoreUser(event as object)
    print "Registration.brs [onStoreUser]"
    status = 0   ' 0 => Finished (got tokens), > 0 => Retry needed
    
    errorMsg = ""
    userData = m.UriHandler.userinfo_response
    isrefresh = false
    
    if userData <> invalid
    
        if userData.code <> 200
            errorMsg = "An Error Occurred in 'onStoreUser'. Code: "+(userData.code).toStr()+" - " +userData.error
        else
            json = ParseJson(userData.content)
            if json = invalid
                errorMsg = "Unable to parse Json response: onStoreUser"
                status = 1
            else if type(json) <> "roAssociativeArray"
                errorMsg = "Json response is not an associative array: onStoreUser"
                status = -1
            else if json.DoesExist("error")
                errorMsg = "Json error response: [onStoreUser] " + json.error
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
                if infoEmail = "" then infoEmail  = "No email on file"
                if infoPhoto = "" then infoPhoto = "pkg:/images/userdefault.png"
                
                if isrefresh = true then
                    m.userInfoName[m.global.selectedUser]  = infoName
                    m.userInfoEmail[m.global.selectedUser] = infoEmail
                    m.userInfoPhoto[m.global.selectedUser] = infoPhoto
                else
                
                    if infoEmail <> "No email on file" then
                        for i = 0 to m.userInfoEmail.Count()-1
                            if m.userInfoEmail[i] = infoEmail and infoEmail<>"No email on file" then
                                m.accessToken.Pop()
                                m.refreshToken.Pop()
                                m.versionToken.Pop()
                                errorMsg = "Account '"  + infoEmail + " is already linked to device"
                                status = 1
                            end if
                        end for
                    end if
                
                    if status = 0 then
                        m.userInfoName.Push(infoName)
                        m.userInfoEmail.Push(infoEmail)
                        m.userInfoPhoto.Push(infoPhoto)
                    end if
                end if
        
                if status = 0 then
                    'Save cached values to registry
                    saveReg()
                    
                    m.Row1.text = ""  
                    m.Row2.text = "Successfully Linked Account!"
                    m.Row3.text = infoName + "'s Google Photos account has been successfully linked to this device"
                    m.Row4.text = ""
                    m.Row5.text = ""
                    
                    m.buttongroup.buttons = [ "Continue" ]
                    m.buttongroup.setFocus(true)
                end if
            end if
        end if
        
        if errorMsg<>"" then
            'ShowNotice
            m.noticeDialog.visible = true
            buttons =  [ "RETRY" ]
            m.noticeDialog.message = errorMsg
            m.noticeDialog.buttons = buttons
            m.noticeDialog.setFocus(true)
            m.noticeDialog.observeField("buttonSelected","noticeClose")
        end if
        
    end if
End Sub


Sub onButtonPress(event as object)
    if (event.getData() = 0) and (m.buttongroup.buttons[0] = "Get a new code")
        'GENERATE NEW TOKEN
        doGenerateToken()
    else if (event.getData() = 0) and (m.buttongroup.buttons[0] = "Continue")
        m.global.selectedUser = -2
    else if (event.getData() = 1)
    
        m.showRegistration.visible = false
    
        m.screenActive     = createObject("roSGNode", "InfoPopup")
        m.screenActive.id  = "AboutChannel"
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
    end if
End Sub


Sub onStopScanningTrigger()
    'ShowNotice
    m.noticeDialog.visible = true
    buttons =  [ "RETRY" ]
    m.noticeDialog.message = "Account linking timed out. Please try again."
    m.noticeDialog.buttons = buttons
    m.noticeDialog.setFocus(true)
    m.noticeDialog.observeField("buttonSelected","noticeClose")
        
    'Stop watching for field changes
    m.UriHandler.unobserveField("gen_token_response")
    m.LoginTimer.unobserveField("fire")
End Sub


Sub noticeClose(event as object)
    m.noticeDialog.visible = false
    m.buttongroup.setFocus(true)
    m.UriHandler.observeField("gen_token_response","onNewToken")
    m.LoginTimer.observeField("fire","onCheckAuth")
    
    doGenerateToken()
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        print "KEY (reg): "; key
        if key = "OK" or key = "back"
            if (m.screenActive <> invalid) and (m.screenActive.id = "AboutChannel")
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                m.showRegistration.visible = true
                m.buttongroup.setFocus(true)
                return true
            end if
        else if key = "right" or key = "left"
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
