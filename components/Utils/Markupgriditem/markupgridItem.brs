
Sub init()
    m.top.id = "markupGridItem"
    m.itemposter = m.top.findNode("itemPoster") 
    m.itemmask = m.top.findNode("itemMask")
End Sub


Sub showcontent()
    itemcontent = m.top.itemContent
    m.itemposter.width = itemcontent.x
    m.itemposter.heith = itemcontent.x
    m.itemposter.uri = itemcontent.hdgridposterurl     
End Sub


Sub showfocus()
    scale = 1 + (m.top.focusPercent * 0.12)
    m.itemposter.scale = [scale, scale]
    m.itemmask.opacity = 0.50 - (m.top.focusPercent * 0.50)
End Sub