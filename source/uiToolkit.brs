
'  uitkDoPosterMenu
'
'    Display "menu" items in a Poster Screen.   
'
function uitkPreShowPosterMenu(breadA=invalid, breadB=invalid, liststyle="arced-square") As Object

    port=CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
    screen.InitClientCertificates()
    if breadA<>invalid and breadB<>invalid then
        breadA=breadA.Replace("Legacy User", "")
        screen.SetBreadcrumbText(breadA, breadB)
    end if
    screen.SetListStyle(liststyle)
    screen.SetListDisplayMode("zoom-to-fill")
    screen.Show()

    return screen
end function


Function uitkDoPosterMenu(posterdata, screen, onselect_callback=invalid) As Integer

    if type(screen)<>"roPosterScreen" then
        print "illegal type/value for screen passed to uitkDoPosterMenu()" 
        return -1
    end if
    
    screen.SetContentList(posterdata)

    while true
        msg = wait(0, screen.GetMessagePort())
        
        'print "uitkDoPosterMenu | msg type = ";type(msg)
        
        if type(msg) = "roPosterScreenEvent" then
            ' print "event.GetType()=";msg.GetType(); " Event.GetMessage()= "; msg.GetMessage()
            if msg.isListItemSelected() then
                if onselect_callback<>invalid then
                    selecttype = onselect_callback[0]
                    if selecttype=0 then
                        this = onselect_callback[1]
                        selected_callback=onselect_callback[msg.GetIndex()+2]
                        if islist(selected_callback) then
                            f=selected_callback[0]
                            userdata1=selected_callback[1]
                            userdata2=selected_callback[2]
                            userdata3=selected_callback[3]
                            
                            if userdata1=invalid then
                                this[f]()
                            else if userdata2=invalid then
                                this[f](userdata1)
                            else if userdata3=invalid then
                                this[f](userdata1, userdata2)
                            else
                                this[f](userdata1, userdata2, userdata3)
                            end if
                        else
                            if selected_callback="return" then
                                return msg.GetIndex()
                            else
                                this[selected_callback]()
                            end if
                        end if
                    else if selecttype=1 then
                        userdata1=onselect_callback[1]
                        userdata2=onselect_callback[2]
                        f=onselect_callback[3]
                        f(userdata1, userdata2, msg.GetIndex())
                    end if
                else
                    return msg.GetIndex()
                end if
            else if msg.isScreenClosed() then
                return -1
            end if
        end if
    end while
End Function


Function uitkDoCategoryMenu(categoryList, screen, content_callback, onclick_callback) As Integer  
    'Set current category to first in list
    category_idx=0
    
    screen.SetListNames(categoryList)
    contentdata1=content_callback[0]
    contentdata2=content_callback[1]
    content_f=content_callback[2]
    
    contentlist=content_f(contentdata1, contentdata2, 0)
    
    if contentlist.Count()=0 then
        screen.SetContentList([])
        screen.SetMessage("No viewable content in this section")
    else
        screen.SetContentList(contentlist)
    end if
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
                category_idx=msg.GetIndex()
                contentdata1=content_callback[0]
                contentdata2=content_callback[1]
                content_f=content_callback[2]
                
                contentlist=content_f(contentdata1, contentdata2, category_idx)
    
                if contentlist.Count()=0 then
                    screen.SetContentList([])
                    screen.ShowMessage("No viewable content in this section")
                else
                    screen.SetContentList(contentlist)
                    screen.SetFocusedListItem(0)
                end if
            else if msg.isListItemSelected() then
                userdata1=onclick_callback[0]
                userdata2=onclick_callback[1]
                content_f=onclick_callback[2]
                
                content_f(userdata1, userdata2, category_idx, msg.GetIndex())
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
End Function

function uitkPreShowGrid(breadA=invalid, breadB=invalid) As Object
    print "---- uitk PreShowGrid  ----"

    screen = CreateObject("roGridScreen")
    port = CreateObject("roMessagePort")
    screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
    screen.InitClientCertificates()
    if breadA<>invalid and breadB<>invalid then
        screen.SetBreadcrumbText(breadA, breadB)
    end if
    if port=invalid then print "roMessagePort Create Failed":stop
    screen.SetDisplayMode("scale-to-fit")
    screen.SetMessagePort(port)
    screen.SetGridStyle("flat-landscape")
    screen.SetCounterVisible(0)
    screen.Show()
    
    return screen
end function

Function uitkDoGrid(imagedata, screen, onselect_callback=invalid) As Integer

    if type(screen)<>"roGridScreen" then
        print "illegal type/value for screen passed to uitkDoGridMenu()" 
        return -1
    end if
    
    categoryList = [Pluralize(imagedata.Count(),"Photo")]
    
    total = imagedata.Count() / 5
    screen.setupLists(ceiling(total))
    
    for i = 1 to ceiling(total)-1
        categoryList.Push("")
    end for
    
    screen.SetListNames(categoryList)
    
    i=0
    r=0
    images_tmp=CreateObject("roList")
    for each record in imagedata
        i = i+1
        images_tmp.Push(record)
        screen.SetContentList(r, images_tmp)
    
        if i = 5 then
            i=0
            r=r+1
            images_tmp.Clear()
        endif 
    next

    'Turnon description box by default. This also helps if there's only 1 photo in row.
    screen.SetDescriptionVisible(1)

    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roGridScreenEvent" then
            screen.SetDescriptionVisible(0)
            'print "msg= "; msg.GetMessage() " , index= "; msg.GetIndex(); " data= "; msg.getData()
            if msg.isListItemFocused() then
                sleep(1000)
                screen.SetDescriptionVisible(1)
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()
                
                'calculate selection - 5 is the number of photos per row for flat-landscape
                itemSelection = row * 5 + selection
                
                print "list item selected row= "; row; " selection= "; selection; " itemSelection= "; itemSelection
                return itemSelection
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
End Function


Sub uitkDoMessage(message, screen)
    screen.showMessage(message)
    while true
        msg = wait(0, screen.GetMessagePort())
        if msg.isScreenClosed() then
            return
        end if
    end while
End Sub
