
Sub AddNextImageToSlideShow(ss, imagelist, counter)
    if imagelist.IsNext() then
        image=imagelist.Next()
        if image.Info=invalid then
            image.Info={}
        end if
        image.Info.url=image.GetURL()
        
        if counter>0 then image.Info.TextOverlayUR=itostr(counter)+" of "+itostr(imagelist.Count())
        image.Info.TextOverlayBody=image.GetTitle() + "  -  " + friendlyDate(strtoi(image.GetTimestamp()))
        
        print image.GetStreamID

        
        ss.AddContent(image.Info)
    end if
End Sub

Function PrepDisplaySlideShow()
    print "---- Prep DisplaySlideShow  ----"
    
    ss = CreateObject("roSlideShow")
    ss.Show()
    ss.SetCertificatesFile("common:/certs/ca-bundle.crt")
    ss.InitClientCertificates()
    mp = CreateObject("roMessagePort")
    if mp=invalid then print "roMessagePort Create Failed":stop
    ss.SetMessagePort(mp)
    ss.SetPeriod(0)
    ss.SetDisplayMode("scale-to-fit")
    ss.AddContent( {url : "file://pkg:/images/slideshow_splash.png"} )
    
    return ss
End Function

function ProcessSlideShowEvent(ss, msg, imagelist, onscreenimage=invalid, title=invalid)
    if type(msg)="roSlideShowEvent" then
        print "roSlideShowEvent. Type ";msg.GetType();", index ";msg.GetIndex();", Data ";msg.GetData();", msg ";msg.GetMessage()
        if msg.isScreenClosed() then
            return true
        else if msg.IsPaused() then
            ss.SetTextOverlayIsVisible(true)
        else if msg.isRemoteKeyPressed() and msg.GetIndex()=3 and ss.CountButtons()=0 then
            ss.SetTextOverlayIsVisible(false)
            ss.ClearButtons()
            if onscreenimage<>invalid then 'This means we are streaming images
                ss.AddButton(0, "Browse Photos")
                ss.AddButton(1, "Cancel")
            end if
        else if msg.IsResumed() then
            ss.SetTextOverlayIsVisible(false)
            ss.ClearButtons()
        else if msg.isButtonPressed() then
            ss.ClearButtons()
            ss.SetTextOverlayIsVisible(false)
            if msg.GetIndex()=0 then 
                ss.Close()'Since we are browsing, this slideshow is no longer necessary
                BrowseImages(imagelist, title)
                return true
            end if
        else if msg.isPlaybackPosition() and onscreenimage<>invalid
            onscreenimage[0]=msg.GetIndex()
            if onscreenimage[0]=imagelist.Count()   'last photo shown
                'Restart slide show, skip splash screen
                ss.SetNext(1, false)
            end if
        end if
    end if
    
    return false
End Function

Sub DisplaySlideShow(ss, imagelist, title, dur)
    print "---- Do DisplaySlideShow  ----"
    
    imagelist.Reset()   ' reset ifEnum
    if not imagelist.IsNext() then return
    sleep(1500) ' let image decode faster; no proof this actually helps

    onscreenimage=[0]  'using a list so i can pass reference instead of pass by value
    port=ss.GetMessagePort()

    ' add all the images to the slide show as fast as possible, while still processing events
    counter=1
    while imagelist.IsNext()
        AddNextimageToSlideShow(ss, imagelist, counter)
        while true
            msg = port.GetMessage()
            if msg=invalid then exit while
            if ProcessSlideShowEvent(ss, msg, imagelist, onscreenimage, title) then return
        end while
        if onscreenimage[0]>0 then
            ss.SetPeriod(dur)
        end if
        counter=counter+1
    end while

    ' all images have been added to the slide show at this point, so just process events
    while true
        if onscreenimage[0]>0 then
            ss.SetPeriod(dur)
        end if
        
        msg = wait(0, port)
        if ProcessSlideShowEvent(ss, msg, imagelist, onscreenimage, title) then return
    end while
End Sub

Sub DisplayImageSet(imagelist As Object, title="" As String, start=0 As Integer, duration=3 As Integer)
    ss=PrepDisplaySlideShow()
    
    'Change order if start is specified
    if start>0 then
        counter=0
        image_idx=start
        copy_imagelist=[]
        while counter<imagelist.Count()
            copy_imagelist.Push(imagelist[image_idx])
            
            if image_idx=imagelist.Count()-1 then
                image_idx=0
            else
                image_idx=image_idx+1
            end if
            
            counter=counter+1
        end while
        
        imagelist=copy_imagelist
    end if
    
    DisplaySlideShow(ss, imagelist, title, duration)
    ss.Close() ' take down roSlideShow
End Sub
