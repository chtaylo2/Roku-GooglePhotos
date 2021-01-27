'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2021 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    'ContentReader is used to read in local XML content.
    m.top.functionName = "getContent"
End Sub


Sub getContent()
    content = createObject("roSGNode", "ContentNode")
    contentxml = createObject("roXMLElement")
    xmlstring = ReadAsciiFile(m.top.file)
    contentxml.parse(xmlstring)

    if contentxml.getName()="Content"
        for each item in contentxml.GetNamedElements("item")
            itemcontent = content.createChild("ContentNode")
            itemcontent.setFields(item.getAttributes())
        end for
    end if

    m.top.content = content
End Sub
