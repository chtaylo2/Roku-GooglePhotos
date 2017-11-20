
sub init()
    'ContentReader components are used to read in local XML content.
    'This does not handle remote content over http(s)
    
    m.top.functionName = "getContent"
end sub


sub getContent()
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
end sub