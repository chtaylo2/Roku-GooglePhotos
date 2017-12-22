
Sub init()

	 m.ImageGrid      = m.top.findNode("ImageGrid")
	 m.itemLabelMain1 = m.top.findNode("itemLabelMain1")
	 m.top.observeField("content","loadImageList")

End Sub


sub loadImageList()
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
	
	m.screenActive = createObject("roSGNode", "DisplayPhotos")
	m.screenActive.startPhoto = m.top.imagesMetaData[m.ImageGrid.itemSelected].url
	m.screenActive.content = m.top.imagesMetaData
    m.top.appendChild(m.screenActive)
	m.screenActive.setFocus(true)
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