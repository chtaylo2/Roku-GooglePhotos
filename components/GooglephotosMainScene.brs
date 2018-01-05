
Sub init()
    'Set scene properties
    m.top.backgroundURI   = ""
    m.top.backgroundColor = "#EBEBEB"
    m.top.setFocus(true)
    
    'Define SG nodes
    m.itemHeader = m.top.findNode("itemHeader")
    
    'Observe user selected
    m.global.selectedUser = -1
    m.global.observeField("selectedUser", "mainLoad")
    
    checkRegistration()
    
End Sub


Function checkRegistration()

    ' Load in the OAuth Registry entries
    loadReg()

    'Check for linked user
    usersLoaded = oauth_count()
    if usersLoaded = 0 then
        m.itemHeader.text   = "Registration"
        m.screenActive      = createObject("roSGNode", "Registration")
        m.screenActive.id   = "Registration"
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
    else
        usersLoaded = oauth_count()
        if usersLoaded = 1 then
            'Show only registered user
            m.global.selectedUser = 0
        else
            selectionLoad()
        end if
    end if
End function


Function selectionLoad()
    m.itemHeader.text   = "Select User"
    m.screenActive      = createObject("roSGNode", "UserSelection")
    m.screenActive.id   = "UserSelection"
    m.top.appendChild(m.screenActive)
    m.screenActive.setFocus(true)
End function


Function mainLoad(event as object)
    if (event.GetData() <> -1 and event.GetData() <> -2)
        'A user was selected, display!
        m.itemHeader.text = ""
        m.top.removeChild(m.screenActive)
        m.screenActive      = createObject("roSGNode", "MainMenu")
        m.screenActive.id   = "MainMenu"
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
    else if event.GetData() = -2
        'A user was unregistered
        m.top.removeChild(m.screenActive)
        m.screenActive = invalid

        checkRegistration()
    end if
End function


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"
            if m.screenActive.id <> "Registration"
                if (m.screenActive <> invalid)
                    m.top.removeChild(m.screenActive)
                    m.screenActive = invalid
                    selectionLoad()
                    return true
                end if
            else
                return true
            end if
        end if
    end if
    return false
End function