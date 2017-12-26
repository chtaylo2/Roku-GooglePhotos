
Sub init()
    m.ImageGrid      = m.top.findNode("ImageGrid")
    m.itemLabelMain1 = m.top.findNode("itemLabelMain1")
    m.top.observeField("content","loadImageList")
End Sub


Sub loadImageList()
    print "Browse.brs [loadImageList]"
    m.ImageGrid.content = m.top.content
    m.itemLabelMain1.text = m.top.albumName
End Sub


Sub addItem(store as object, hdgridposterurl as string)
    item = store.createChild("ContentNode")
    item.hdgridposterurl = hdgridposterurl
End Sub


Sub onItemSelected()
    'Item selected
    print "SELECTED: "; m.ImageGrid.itemSelected
    print "ID: "; m.top.id
    
    
    if m.top.id = "GP_IMAGE_BROWSE" then
        m.screenActive = createObject("roSGNode", "DisplayPhotos")
        m.screenActive.startPhoto = m.top.metaData[m.ImageGrid.itemSelected].url
        m.screenActive.content = m.top.metaData
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
        
    else if m.top.id = "GP_VIDEO_BROWSE" then
        m.screenActive = createObject("roSGNode", "DisplayVideo")
        m.screenActive.videoUrl = m.top.metaData[m.ImageGrid.itemSelected].url
        m.top.appendChild(m.screenActive)
        m.screenActive.setFocus(true)
    end if
End Sub


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key = "back"
            if (m.screenActive <> invalid)
                m.top.removeChild(m.screenActive)
                m.screenActive = invalid
                m.ImageGrid.setFocus(true)
                return true
            end if
        end if 
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function