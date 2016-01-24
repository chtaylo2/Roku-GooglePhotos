Sub RunScreensaver()
    ba=CreateObject("roByteArray")
    canvas=CreateObject("roImageCanvas")
    port=CreateObject("roMessagePort")
    device=CreateObject("roDeviceInfo")
    
    ds=device.GetDisplaySize()
    
    Init()
    REM oa = Oauth()
    REM picasa = LoadPicasa()
    
    sstype=RegRead("ScreensaverType","Settings")
    REM if sstype<>invalid then sstype=Val(sstype)
    if sstype=invalid
        if m.oa.linked()
            sstype=1
        else
            sstype=0
        end if
    else
        sstype=Val(sstype)
    end if

    if not m.oa.linked() or sstype=0 then
        rsp=m.picasa.ExecServerAPI("featured?max-results=300&v=2.0&fields=entry(media:group(media:content))&imgmax=400", invalid)
    else
        rsp=m.picasa.ExecServerAPI("?kind=photo&max-results=300&v=2.0&fields=entry(media:group(media:content))&imgmax=400")
    end if

    canvasItems=[]
    if isxmlelement(rsp) then 
        images=picasa_new_image_list(rsp.entry)
        for each image in images
            canvasItems.Push(image.GetURL())
        end for
    end if    
    
    canvas.SetMessagePort(port)
    canvas.PurgeCachedImages()
    canvas.SetRequireAllImagesToDraw(true)
    canvas.SetLayer(0, {Color:"#FF000000", CompositionMode:"Source"})
    canvas.Show()
    counter=Rnd(canvasItems.Count())-1
    while(true)
        'Reset counter if end
        nextimg=Rnd(canvasItems.Count())-1
        
        canvasItem=[
            {url: canvasItems[counter],
             TargetRect:{x:Rnd(ds.w-420), y:Rnd(ds.h-300)}},
            {url: canvasItems[nextimg],
            TargetRect:{x:-1000, y:-1000}}   'Off the screen to preload     
        ]
        
        canvas.SetLayer(2, {Color:"#FF000000", CompositionMode:"Source"})
        canvas.SetLayer(1, canvasItem)
        HandleCanvasPort(port, 1000, canvas)
        
        for i=255 to -1 step -8
            if i=-1 then i=0
            ba[0]=i
            ab=ba.ToHexString()
            canvas.SetLayer(2, {Color:"#"+ab+"000000", CompositionMode:"Source_Over"})
            canvas.Show()
            HandleCanvasPort(port, 32, canvas)
        end for
        
        HandleCanvasPort(port, 12000, canvas)
        
        for i=0 to 256 step 8
            if i=256 then i=255
            ba[0]=i
            ab=ba.ToHexString()
            canvas.SetLayer(2, {Color:"#"+ab+"000000", CompositionMode:"Source_Over"})
            canvas.Show()
            HandleCanvasPort(port, 32, canvas)
        end for
        
        counter=nextimg
    end while
End Sub

Sub HandleCanvasPort(port, wait, canvas)
    msg = wait(wait, port)
    if type(msg) = "roImageCanvasEvent" then
        if (msg.isRemoteKeyPressed()) then
            i = msg.GetIndex()
            print "Key Pressed - " ; msg.GetIndex()
            ' Up - Close the screen.
            canvas.close()
            end
        else if (msg.isScreenClosed()) then
            print "Closed"
            end
        end if
    end if
End Sub

Sub RunScreenSaverSettings()
    initTheme()
    Init()
    REM oa = Oauth()
    
    linked=m.oa.linked()
    
    if linked then
        
        sstype=RegRead("ScreensaverType","Settings")
        if sstype<>invalid then sstype=Val(sstype)
        
        if sstype=invalid then
            typetext="not set (Your Photos)"
        else
            if sstype=0 then
                typetext="Featured Photos"
            else
                typetext="Your Photos"
            end if
        end if
    end if
    
    port = CreateObject("roMessagePort")
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)
    
    screen.AddHeaderText("Screensaver Settings")
    if linked then
        screen.AddParagraph("Choose the type of photos to show in your screensaver")
        screen.AddParagraph("Current setting: "+typetext)
        screen.AddButton(0, "Featured Photos")
        screen.AddButton(1, "Your Photos")
    else
        screen.AddParagraph("Your Picasa Web Albums account is not linked.  You will view Featured Photos.  Link your account through the regular Picasa channel to view your personal photos.")
    end if
    screen.AddButton(99, "Back")
    screen.Show()
    
    while true
        msg = wait(0, screen.GetMessagePort())
        
        if type(msg) = "roParagraphScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                button_idx=msg.GetIndex()
                if button_idx = 0 or button_idx = 1 then
                    RegWrite("ScreensaverType",Str(button_idx),"Settings")
                end if
                exit while
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                exit while
            end if
        end if
    end while
End Sub