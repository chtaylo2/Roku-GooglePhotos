
' This is our slideshow function declaration script.
' Since ROKU doesn't support global functions, the following must be added to each XML file where needed
' <script type="text/brightscript" uri="pkg:/components/Utils/SlideshowHelper.brs" />


'*********************************************************
'**
'** OAUTH HANDLERS
'**
'*********************************************************

Function handleRefreshToken(event as object)
    print "SlideshowHelper.brs [handleRefreshToken]"

    refreshData = m.UriHandler.refreshToken
        
    if refreshData <> invalid
        json = ParseJson(refreshData.content)
        if json = invalid
            m.errorMsg = "Unable to parse Json response"
            status = 1
        else if type(json) <> "roAssociativeArray"
            m.errorMsg = "Json response is not an associative array"
            status = -1
        else if json.DoesExist("error")
            m.errorMsg = "Json error response: " + json.error
            status = 1
        else
            
            ' We have our tokens
            m.accessToken[m.global.selectedUser]  = getString(json,"access_token")
            m.tokenType                           = getString(json,"token_type")
            m.tokenExpiresIn                      = getInteger(json,"expires_in")
            refreshToken                          = getString(json,"refresh_token")
            if refreshToken <> ""
                m.refreshToken[m.global.selectedUser] = refreshToken
            end if

            'Query User info
            'status = m.RequestUserInfo(m.accessToken.Count()-1, false)

            if m.tokenType       = "" then m.errorMsg = "Missing token_type"      : status = 1
            if m.tokenExpiresIn  = 0  then m.errorMsg = "Missing expires_in"      : status = 1

            'Save cached values to registry
            saveReg()                
        end if   
    end if
	
	'Yes - shouldnt default to this. only temporary.
	doGetAlbumList()
	
End Function


'*********************************************************
'**
'** ALBUM HANDLERS
'**
'*********************************************************

' Create full album list from XML response
Function googleAlbumListing(xmllist As Object) As Object
    albumlist=CreateObject("roList")
    for each record in xmllist
        album=googleAlbumCreateRecord(record)
        if album.GetImageCount() > 0 then
			' Do not show photos from Google Hangout albums or any marked with "Private" in name
			if album.GetTitle().instr("Hangout:") = -1 and album.GetTitle().instr("rivate") = -1 then
				albumlist.Push(album)
			end if
        end if
    next
    
    return albumlist
End Function


' Create single album record from XML entry
Function googleAlbumCreateRecord(xml As Object) As Object
    album = CreateObject("roAssociativeArray")
    album.xml=xml

    album.GetUsername=function():return m.xml.GetNamedElements("gphoto:user")[0].GetText():end function
    album.GetTitle=function():return m.xml.title[0].GetText():end function
    album.GetID=function():return m.xml.GetNamedElements("gphoto:id")[0].GetText():end function
    album.GetImageCount=function():return Val(m.xml.GetNamedElements("gphoto:numphotos")[0].GetText()):end function
    album.GetThumb=get_thumb
	
    return album
End Function



' ********************************************************************
' **
' ** IMAGE HANDLERS
' **
' ********************************************************************

Function googleImageListing(xmllist As Object, showall=0 as Integer) As Object
      images=CreateObject("roList")
      for each record in xmllist
            image=googleImageCreateRecord(record)
            if image.GetURL()<>invalid then
                  if image.GetStreamID.instr(":archive:") = -1 or showall=1
                        images.Push(image)
                  end if
            end if
      next
    
      return images
End Function


Function googleImageCreateRecord(xml As Object) As Object
      image = CreateObject("roAssociativeArray")
      image.xml=xml
      image.GetTitle=function():return m.xml.GetNamedElements("title")[0].GetText():end function
      image.GetID=function():return m.xml.GetNamedElements("gphoto:id")[0].GetText():end function
      image.GetURL=get_image_url
      image.GetThumb=get_thumb
      image.GetTimestamp=function():return Left(m.xml.GetNamedElements("gphoto:timestamp")[0].GetText(), 10):end function
      image.IsVideo=function():return (m.xml.GetNamedElements("gphoto:videostatus")[0]<>invalid):end function
      image.GetVideoStatus=function():return m.xml.GetNamedElements("gphoto:videostatus")[0].GetText():end function
	
      i=0
      image.GetStreamID = ""
      for each streamid in xml.GetNamedElements("gphoto:streamId")
            image.GetStreamID = ":" + image.GetStreamID + ":" + xml.GetNamedElements("gphoto:streamId")[i].GetText()
            i=i+1
      end for
	
      return image
End Function


Function get_thumb()
      if m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail").Count()>0 then
            return m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:thumbnail")[0].GetAttributes()["url"]
      end if
    
      return "pkg:/images/icon_s.png"
End Function


Function get_image_url()
      images=m.xml.GetNamedElements("media:group")[0].GetNamedElements("media:content")
      if m.IsVideo() then
            if m.GetVideoStatus()="final" or m.GetVideoStatus()="ready" then
                  for each image in images
                        if image.GetAttributes()["type"]="video/mpeg4" then
                              return image.GetAttributes()["url"]
                        end if
                  end for
            end if
      else
            if images[0]<>invalid then
                  return images[0].GetAttributes()["url"]
            end if
      end if
    
      return invalid
End Function