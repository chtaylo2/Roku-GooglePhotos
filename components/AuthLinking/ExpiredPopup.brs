'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2021 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()     
    'Load common variables
    loadCommon()
    
    ' Load in the OAuth Registry entries
    loadReg()    
    
    'Define SG nodes
    m.itemLabelHeader = m.top.findNode("itemLabelHeader")
    m.itemLabelMain   = m.top.findNode("itemLabelMain")
    m.buttonGroup     = m.top.findNode("buttonGroup")
    
    m.buttonGroup.buttons = [ "Re-Register" ]
    m.buttonGroup.setFocus(true)
    m.buttonGroup.observeField("buttonSelected","onButtonPress")
    
    m.top.observeField("id","loadingComplete")

End Sub


Sub loadingComplete()
    if m.top.id = "ExpiredPopup" then
        setExpiredText()
    else if m.top.id = "RelinkPopup"
        setRelinkText()
    end if
End Sub


Sub setExpiredText()
    m.itemLabelHeader.text = "Google Photos Access Expired"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "We're having trouble refreshing your access token. This is common if it's been over 6 months since you used this channel. A Google password reset and revoking of access are also other common reasons."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "Select the Re-Register button below to link your account back to this device!"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "If you feel this might be in error, please exit the channel and try again later."
End Sub


Sub setRelinkText()
    m.itemLabelHeader.text = "Google Photos Re-Authorization Required"
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + "Our channel has migrated to the new Google Photos API so you'll need to re-authorize your account access."
    m.itemLabelMain.text = m.itemLabelMain.text + chr(10) + chr(10) + "It's simple! Select the Re-Register button below to complete this action."
End Sub


Sub onButtonPress(event as object)
    loadItems()
    for each item in m.items
        m.[item].Delete(m.global.selectedUser)
        print m.[item]
    end for
    saveReg()
    
    'Check for linked user
    usersLoaded = oauth_count()
    
    m.global.selectedUser = -3
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
End function
