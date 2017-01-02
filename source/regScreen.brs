Sub doRegistration()

    oa = Oauth()
    
    if not oa.linked()
        ' We're not already linked, so attempt to link
        while doGooglePhotosEnroll() <> 0
        end while
        
        ' Check if the link was successful
        if oa.linked()
            ' Successful link, save access token and refresh token in registry
            oa.save()
            print "doRegistration. linked. oauth: "; oa.dump()
            showCongratulationsScreen()
        else
            ' We are not linked, delete access token and refresh token from registry
            oa.erase()
            print "doRegistration. not linked"
        end if
    end if
 
End Sub

Sub doAdditionalReg()

    oa = Oauth()
    
    'if not oa.linked()
        ' We're not already linked, so attempt to link
        while doGooglePhotosEnroll() <> 0
        end while
        
        ' Check if the link was successful
        if oa.linked()
            ' Successful link, save access token and refresh token in registry
            oa.save()
            print "doRegistration. linked. oauth: "; oa.dump()
            showCongratulationsScreen()
        else
            ' We are not linked, delete access token and refresh token from registry
            oa.erase()
            print "doRegistration. not linked"
        end if
    'end if
 
End Sub


Function doGooglePhotosEnroll() As Integer
    print "regScreen: doGooglePhotosEnroll"
    status = 0    ' 0 => finished, <> 0 => retry needed

    googlephotos = LoadGooglePhotos()
    oa = Oauth()
    ts = CreateObject("roTimespan")

    ' Send an OAuth2 request for a user code
    status = oa.RequestUserCode()    
    if status = 0
        ' We have a code - start the poll duration timer
        ts.Mark()
        print "doGooglePhotosEnroll. User Code: "; oa.userCode
    else
        ' Failed to get a code
        print "doGooglePhotosEnroll: failed to retrieve user code"
        print "doGooglePhotosEnroll. oauth: "; oa.dump()

        ans=ShowDialog2Buttons("OAuth2 user code request failed", oa.errorMsg, "Try Again", "Back")
        if ans=0
            status = 1    ' Retry
        end if

        return status
    end if

    ' Display the registration screen, populated with the user code and registration url
    regscreen = displayRegistrationScreen()
    
    ' Polling loop - keep polling to see if the device has been registered with Google
    while true
        print "Polling"

        ' Issue an OAuth2 poll request to check whether the user has entered the code yet on their computer
        status = oa.PollForTokens()
        if status = 0
            ' The user has entered the code on their computer
            return status
        else if status > 0
            ' An error occurred
            ans=ShowDialog2Buttons("OAuth2 polling request failed", oa.errorMsg, "Try Again", "Back")
            if ans=0
                status = 1    ' Retry
            else
                status = 0
            end if
            return status
        else
            ' status < 0 ==> keep polling
        endif

        ' reset status to ensure we terminate unless user wants to retry
        status = 0

        'wait for the retry interval to expire or the user to press a button
        'indicating they either want to quit or fetch a new registration code
        while true
            msg = wait((oa.interval + oa.pollDelay) * 1000, regscreen.GetMessagePort())
            if msg = invalid
                if ts.TotalSeconds() >= oa.pollExpiresIn
                    ans=ShowDialog2Buttons("Request timed out", "Unable to link to Google Photos within time limit.", "Try Again", "Back")
                    if ans=0 then 
                        status = 1    ' Retry
                    end if
                    return status
                else
                    exit while        ' Poll again
                end if
            else
                if type(msg) = "roCodeRegistrationScreenEvent"
                    if msg.isScreenClosed()
                        return status
                    elseif msg.isButtonPressed()
                        if msg.GetIndex() = 0
                            status = 1        ' Make sure we loop again to get a new code
                        end if
                        return status
                    end if
                end if
            end if
        end while                    
    end while
    
    return status
End Function

'******************************************************
'Load/Save a set of parameters to registry
'These functions must be called from an AA that has
'a "section" string and an "items" list of strings.
'******************************************************
Function loadReg() As Boolean
    for each item in m.items
        temp =  RegRead(item, m.section)
        if temp = invalid then temp = ""
        m[item] = temp
    end for
    return m.linked()
End Function

Function saveReg()
    for each item in m.items
        RegWrite(item, m[item], m.section)
    end for
End Function

Function eraseReg()
    for each item in m.items
        RegDelete(item, m.section)
        m[item] = ""
    end for
End Function

Function definedReg() As Boolean
    for each item in m.items
        if not m.DoesExist(item) then return false
        if Len(m[item])=0 then return false
    end for
    return true
End Function

Function dumpReg() As String
    result = ""
    for each item in m.items
        if m.DoesExist(item) then result = result + " " +item+"="+m[item]
    end for
    return result
End Function

Function displayRegistrationScreen() As Object
    oa = Oauth()
    
    regscreen = CreateObject("roCodeRegistrationScreen")
    regscreen.SetMessagePort(CreateObject("roMessagePort"))
    
    regscreen.SetTitle("")
    regscreen.AddParagraph("Please link your Roku player to your Google Photos account")
    regscreen.AddFocalText(" ", "spacing-dense")
    regscreen.AddFocalText("From your computer, go to:" + Chr(10), "spacing-dense")
    regscreen.AddFocalText(oa.verificationUrl, "spacing-dense")
    regscreen.AddFocalText(Chr(10) + "and enter this code:", "spacing-dense")
    regscreen.SetRegistrationCode(oa.userCode)
    regscreen.AddParagraph("This screen will automatically update as soon as your activation completes")
    regscreen.AddButton(0, "Get a new code")
    regscreen.AddButton(1, "Back")
    regscreen.Show()
    
    return regscreen
End Function

'******************************************************
'Show congratulations screen
'******************************************************
Sub showCongratulationsScreen()
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    
    screen.AddHeaderText("Congratulations!")
    screen.AddParagraph("You have successfully linked your Roku player to your Google Photos account")
    screen.AddParagraph("Select 'Start' to begin.")
    screen.AddButton(1, "Start")
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " "; msg.GetData()
                exit while 
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub
