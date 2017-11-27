
Sub init()
				
    m.FadeBackground = m.top.findNode("FadeBackground")
	m.PrimaryImage = m.top.findNode("PrimaryImage")
	m.RotationTimer = m.top.findNode("RotationTimer")
	
	
	
	'Center the MarkUp Box
	'markupRectAlbum = m.PrimaryImage.boundingRect()
	'centerx = (1280 - markupRectAlbum.width) / 2
	'centery = (720 - markupRectAlbum.height) / 2

	'm.PrimaryImage.translation = [ centerx, centery ]
	
	print m.PrimaryImage.translation
	
	m.RotationTimer.observeField("fire","onTimerTigger")
	
	m.RotationTimer.repeat = true
    m.RotationTimer.control = "start"
	
End Sub

sub onTimerTigger(event as object)
    print "Registration.brs [onTimerTigger]"
	
	rnd = GetNext(m.top.content)
	print "RANDOM: "; rnd
	print "ITEM: "; m.top.content[rnd]
	
	url = m.top.content[rnd].GetURL
	
	print "CONTENT: "; url
	
	
	m.PrimaryImage.uri = "https://lh3.googleusercontent.com/-qPvTul2tmls/WhpXs_9XWlI/AAAAAAAAJpw/McT33zEXvQoXefXJh5LYDERTFil3yPdRACHMYBhgL/s720/IMG_5686.JPG"
	
End Sub

Function GetNext(items As Object)
	return Rnd(items.Count())-1
End Function