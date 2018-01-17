Sub init()
			
	device = CreateObject("roDeviceInfo")
    ds = device.GetDisplaySize()

    m.WaveStep          = 0
	m.imageTracker      = -1
    m.multiplier        = 1
    loadmultiplier      = 1
    if ds.w = 1920 then
        print "FHD detected"
        m.multiplier    = 1.5
        loadmultiplier  = 1.6
    end if
    
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
    
    m.WaveTimer.observeField("fire","onWaveTigger")
	m.RefreshTimer.observeField("fire","onRefreshTigger")
	
    'Node 1 adjustments
        tmpStart = []
        tmpStart.Push(50*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_1.loadWidth           = 150*loadmultiplier
        m.scroll_node_1.loadHeight          = 150*loadmultiplier
        m.scroll_node_1.imageTranslation    = tmpStart
        m.scroll_node_1.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"
            
    'Node 2 adjustments
        tmpStart = []
        tmpStart.Push(300*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_2.loadWidth           = 250*loadmultiplier
        m.scroll_node_2.loadHeight          = 250*loadmultiplier
        m.scroll_node_2.imageTranslation    = tmpStart
        m.scroll_node_2.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"

    'Node 3 adjustments
        tmpStart = []
        tmpStart.Push(875*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_3.loadWidth           = 150*loadmultiplier
        m.scroll_node_3.loadHeight          = 150*loadmultiplier
        m.scroll_node_3.imageTranslation    = tmpStart
        m.scroll_node_3.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"
                
    'Node 4 adjustments
        tmpStart = []
        tmpStart.Push(700*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_4.loadWidth           = 215*loadmultiplier
        m.scroll_node_4.loadHeight          = 215*loadmultiplier
        m.scroll_node_4.imageTranslation    = tmpStart
        m.scroll_node_4.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"

    'Node 5 adjustments
        tmpStart = []
        tmpStart.Push(450*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_5.loadWidth           = 300*loadmultiplier
        m.scroll_node_5.loadHeight          = 300*loadmultiplier
        m.scroll_node_5.imageTranslation    = tmpStart
        m.scroll_node_5.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"

    'Node 6 adjustments
        tmpStart = []
        tmpStart.Push(1000*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_6.loadWidth           = 250*loadmultiplier
        m.scroll_node_6.loadHeight          = 250*loadmultiplier
        m.scroll_node_6.imageTranslation    = tmpStart
        m.scroll_node_6.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"

    'Node 7 adjustments
        tmpStart = []
        tmpStart.Push(600*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_7.loadWidth           = 375*loadmultiplier
        m.scroll_node_7.loadHeight          = 375*loadmultiplier
        m.scroll_node_7.imageTranslation    = tmpStart
        m.scroll_node_7.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"

    'Node 8 adjustments
        tmpStart = []
        tmpStart.Push(100*m.multiplier)
        tmpStart.Push(730*m.multiplier)
        m.scroll_node_8.loadWidth           = 375*loadmultiplier
        m.scroll_node_8.loadHeight          = 375*loadmultiplier
        m.scroll_node_8.imageTranslation    = tmpStart
        m.scroll_node_8.ventorTranslation   = "[["+str(tmpStart[0])+","+str(tmpStart[1])+"],["+str(tmpStart[0])+","+str(-400*m.multiplier)+"]]"
				
	
    m.top.observeField("content","loadImages")
				
End Sub


sub loadImages()
    m.scroll_node_1.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_5.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_6.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_4.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_8.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_2.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_3.imageUri    = GetNextImage(m.top.content, m.imageTracker)
    m.scroll_node_7.imageUri    = GetNextImage(m.top.content, m.imageTracker)
	
    m.scroll_node_1.control	    = "start"
    m.scroll_node_5.control	    = "start"
	m.WaveTimer.control		    = "start"
    m.RefreshTimer.control      = "start"
	
end sub


Sub onWaveTigger()
	if m.WaveStep = 0 then
		m.scroll_node_6.control	= "start"
	else if m.WaveStep = 1
		m.scroll_node_4.control	= "start"
        m.scroll_node_8.control	= "start"'
	else if m.WaveStep = 2
        m.scroll_node_2.control	= "start"
        m.scroll_node_3.control	= "start"
        m.scroll_node_7.control	= "start"
		m.WaveTimer.control 	= "stop"
	end if

	m.WaveStep = m.WaveStep + 1

End Sub

sub onRefreshTigger()

    'FHD Support
    endPoint=-400*m.multiplier
    
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