'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2021 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    'Load common variables
    loadCommon()
    
    'Define SG nodes
    m.itemLabelHeader   = m.top.findNode("itemLabelHeader")
    m.itemLabelMain     = m.top.findNode("itemLabelMain")
    m.buttonContinue    = m.top.findNode("buttonContinue")
    m.updateField       = m.top.findNode("updateField")
    
    m.buttonContinue.setFocus(true)
    m.top.observeField("id","loadingComplete")    
End Sub


Sub loadingComplete()
    m.itemLabelMain.text = m.top.content
End Sub

Function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
End function
