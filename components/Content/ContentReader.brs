
sub init()
    m.top.functionName = "getContent"
end sub


sub getContent()
    content = createObject("roSGNode", "ContentNode")

    contentxml = createObject("roXMLElement")

    xmlstring = ReadAsciiFile(m.top.contenturi)
    contentxml.parse(xmlstring)
      
    'readInternet = createObject("roUrlTransfer")
    'readInternet.setUrl(m.top.contenturi)
    'contentxml.parse(readInternet.GetToString())

    if contentxml.getName()="Content"
        for each item in contentxml.GetNamedElements("item")
            itemcontent = content.createChild("ContentNode")
            itemcontent.setFields(item.getAttributes())
        end for
    end if

    m.top.content = content
end sub