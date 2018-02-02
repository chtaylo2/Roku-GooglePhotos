'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
        
    m.WaveStep          = 0
    m.imageTracker      = -1

    m.scroll_node_1 = m.top.findNode("scroll_node_1")
    m.scroll_node_2 = m.top.findNode("scroll_node_2")
    m.scroll_node_3 = m.top.findNode("scroll_node_3")
    m.scroll_node_4 = m.top.findNode("scroll_node_4")
    m.scroll_node_5 = m.top.findNode("scroll_node_5")
    m.scroll_node_6 = m.top.findNode("scroll_node_6")
    m.scroll_node_7 = m.top.findNode("scroll_node_7")
    m.scroll_node_8 = m.top.findNode("scroll_node_8")

    m.WaveTimer     = m.top.findNode("waveTimer")
    m.RefreshTimer  = m.top.findNode("refreshTimer")
    m.Watermark     = m.top.findNode("Watermark")
    m.MoveTimer     = m.top.findNode("moveWatermark")
    
    m.WaveTimer.observeField("fire","onWaveTigger")
    m.RefreshTimer.observeField("fire","onRefreshTigger")
    
    endPoint=-600
    
    'Node 1 adjustments
        tmpStart = []
        tmpStart.Push(75)
        tmpStart.Push(1095)
        m.scroll_node_1.loadWidth           = 225
        m.scroll_node_1.loadHeight          = 225
        m.scroll_node_1.imageTranslation    = tmpStart
        m.scroll_node_1.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"
            
    'Node 2 adjustments
        tmpStart = []
        tmpStart.Push(450)
        tmpStart.Push(1095)
        m.scroll_node_2.loadWidth           = 375
        m.scroll_node_2.loadHeight          = 375
        m.scroll_node_2.imageTranslation    = tmpStart
        m.scroll_node_2.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 3 adjustments
        tmpStart = []
        tmpStart.Push(1314)
        tmpStart.Push(1095)
        m.scroll_node_3.loadWidth           = 225
        m.scroll_node_3.loadHeight          = 225
        m.scroll_node_3.imageTranslation    = tmpStart
        m.scroll_node_3.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"
                
    'Node 4 adjustments
        tmpStart = []
        tmpStart.Push(1050)
        tmpStart.Push(1095)
        m.scroll_node_4.loadWidth           = 324
        m.scroll_node_4.loadHeight          = 324
        m.scroll_node_4.imageTranslation    = tmpStart
        m.scroll_node_4.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 5 adjustments
        tmpStart = []
        tmpStart.Push(675)
        tmpStart.Push(1095)
        m.scroll_node_5.loadWidth           = 450
        m.scroll_node_5.loadHeight          = 450
        m.scroll_node_5.imageTranslation    = tmpStart
        m.scroll_node_5.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 6 adjustments
        tmpStart = []
        tmpStart.Push(1500)
        tmpStart.Push(1095)
        m.scroll_node_6.loadWidth           = 375
        m.scroll_node_6.loadHeight          = 375
        m.scroll_node_6.imageTranslation    = tmpStart
        m.scroll_node_6.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 7 adjustments
        tmpStart = []
        tmpStart.Push(900)
        tmpStart.Push(1095)
        m.scroll_node_7.loadWidth           = 564
        m.scroll_node_7.loadHeight          = 564
        m.scroll_node_7.imageTranslation    = tmpStart
        m.scroll_node_7.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"

    'Node 8 adjustments
        tmpStart = []
        tmpStart.Push(150)
        tmpStart.Push(1095)
        m.scroll_node_8.loadWidth           = 564
        m.scroll_node_8.loadHeight          = 564
        m.scroll_node_8.imageTranslation    = tmpStart
        m.scroll_node_8.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(endPoint)+"]]"
                
    m.top.observeField("loaded","loadImages")
End Sub


Sub loadImages()
    m.scroll_node_1.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_5.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_6.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_4.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_8.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_2.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_3.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_7.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    
    if m.top.id = "DisplayScreensaver" then
        'Show watermark on screensaver - Stop bitching, we need some advertisment!
        device  = createObject("roDeviceInfo")
        ds = device.GetDisplaySize()

        if ds.w = 1920 then
            m.Watermark.uri = "pkg:/images/PhotoViewWatermark_FHD.png"
        else
            m.Watermark.uri = "pkg:/images/PhotoViewWatermark_HD.png"
        end if
        m.Watermark.visible = true
        
        m.MoveTimer.observeField("fire","onMoveTrigger")
        m.MoveTimer.control = "start"
        
    end if
    
    m.scroll_node_1.control     = "start"
    m.scroll_node_5.control     = "start"
    m.WaveTimer.control         = "start"
    m.RefreshTimer.control      = "start"
    
End Sub


Sub onMoveTrigger()
    'To prevent screen burn-in
    if m.Watermark.translation[1] = 1010 then
         m.Watermark.translation = "[1700,10]"
    else
        m.Watermark.translation = "[1700,1010]"
    end if
End Sub


Sub onWaveTigger()
    if m.WaveStep = 0 then
        m.scroll_node_6.control = "start"
    else if m.WaveStep = 1
        m.scroll_node_4.control = "start"
        m.scroll_node_8.control = "start"'
    else if m.WaveStep = 2
        m.scroll_node_2.control = "start"
        m.scroll_node_3.control = "start"
        m.scroll_node_7.control = "start"
        m.WaveTimer.control     = "stop"
    end if

    m.WaveStep = m.WaveStep + 1

End Sub


Sub onRefreshTigger()

    'FHD Support
    endPoint=-600
    
    if (m.scroll_node_1.imageTranslation[1] = endPoint) then
        m.scroll_node_1.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_1.control     = "start"
    end if
 
    if (m.scroll_node_2.imageTranslation[1] = endPoint) then
        m.scroll_node_2.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_2.control     = "start"
    end if

    if (m.scroll_node_3.imageTranslation[1] = endPoint) then
        m.scroll_node_3.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_3.control     = "start"
    end if
        
    if (m.scroll_node_4.imageTranslation[1] = endPoint) then
        m.scroll_node_4.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_4.control     = "start"
    end if

    if (m.scroll_node_5.imageTranslation[1] = endPoint) then
        m.scroll_node_5.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_5.control     = "start"
    end if

    if (m.scroll_node_6.imageTranslation[1] = endPoint) then
        m.scroll_node_6.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_6.control     = "start"
    end if
            
    if (m.scroll_node_7.imageTranslation[1] = endPoint) then
        m.scroll_node_7.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_7.control     = "start"
    end if
            
    if (m.scroll_node_8.imageTranslation[1] = endPoint) then
        m.scroll_node_8.imageUri    = GetNextImage(m.top.content, m.imageTracker)
        m.scroll_node_8.control     = "start"
    end if       
    
    m.keyResetTask = createObject("roSGNode", "KeyReset")
    m.keyResetTask.control = "RUN"
    
End Sub


Function GetNextImage(items As Object, tracker As Integer)
    if items.Count()-1 = tracker then
        m.imageTracker = 0
        url = m.top.content[m.imageTracker].url
        return url
    else
        m.imageTracker = tracker + 1
        url = m.top.content[m.imageTracker].url
        return url
    end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
    if press then
        if key <> "back"
            return true
        end if
    end if

    'If nothing above is true, we'll fall back to the previous screen.
    return false
End Function
