
' This is our global function declaration script.
' Since ROKU doesn't support global functions, the following must be added to each XML file where needed
' <script type="text/brightscript" uri="pkg:/components/Utils/HelperFunctions.brs" />


Function RegRead(key, section=invalid)
      if section = invalid then section = "Default"
      sec = CreateObject("roRegistrySection", section)
      if sec.Exists(key) then return sec.Read(key)
      return invalid
End Function


Function RegWrite(key, val, section=invalid)
      if section = invalid then section = "Default"
      sec = CreateObject("roRegistrySection", section)
      sec.Write(key, val)
      sec.Flush() 'commit it
End Function


Function RegDelete(key, section=invalid)
      if section = invalid then section = "Default"
      sec = CreateObject("roRegistrySection", section)
      sec.Delete(key)
      sec.Flush()
End Function
      

Function loadCommon()
      ' Common varables for needed for Oauth and GooglePhotos API
      
      m.releaseVersion  = "1.7"
      m.gp_scope        = "https://picasaweb.google.com/data"
      m.gp_prefix       = m.gp_scope + "/feed/api/user/default"
      
      m.clientId        = getClientId()
      m.clientSecret    = getClientSecret()
    
      m.oauth_prefix    = "https://accounts.google.com/o/oauth2"
      m.oauth_scope     = "https://picasaweb.google.com/data https://www.googleapis.com/auth/userinfo.email"
      
End Function

Function loadItems()
      m.section   = "GooglePhotos-Auth"
      m.items     = CreateObject("roList")
      m.items.push("accessToken")
      m.items.push("refreshToken")
      m.items.push("userInfoName")
      m.items.push("userInfoEmail")
      m.items.push("userInfoPhoto")
End Function


'*********************************************************
'**
'** Load tokens from registry
'**
'*********************************************************
Function loadReg() As Boolean

      loadItems()
      for each item in m.items
            temp =  RegRead(item, m.section)
            if temp = invalid then temp = ""
            m[item] = temp.Split(",")
            if m[item][0] = "" then m[item].shift()
        
            print "LOAD REG ["; item; "] = "; temp
      end for

      'Legacy Support
      if m.accessToken[0]<>invalid and m.userInfoName[0]=invalid then
            m.userInfoName.Push("Legacy User")
            m.userInfoEmail.Push("Relink account to pull user details (then remove this link in Settings)")
            m.userInfoPhoto.Push("pkg:/images/userdefault.png")
      end if
End Function


'*********************************************************
'**
'** Save tokens to registry
'**
'*********************************************************
Function saveReg()

      loadItems()
      for each item in m.items
            value=""
            for i = 0 to m[item].Count()-1
                  if i = m[item].Count()-1 then
                        value = value+m[item][i]
                  else
                        value = value+m[item][i]+","
                  end if
            end for
        
            print "SAVE REG ["; item; "] = "; value
    
            RegWrite(item, value, m.section)
    end for
End Function


'*********************************************************
'**
'** Erase tokens from registry
'**
'*********************************************************
Function eraseReg()

      loadItems()
      for each item in m.items
            RegDelete(item, m.section)
            m[item].Clear()
      end for
End Function


Function definedReg() As Boolean

      loadItems()
      
      'Legacy Support
      if m.accessToken[0]<>invalid and m.userInfoName[0]=invalid then
            m.userInfoName.Push("Legacy User")
            m.userInfoEmail.Push("Relink account to pull user details (then remove this link in Settings)")
            m.userInfoPhoto.Push("pkg:/images/userdefault.png")
      end if

      for each item in m.items
            if m[item] = invalid Or m[item].Count()=0 then return false
      end for
      return true
End Function


Function dumpReg() As String

      loadItems()
      result = ""
      for each item in m.items
            value=""
            for i = 0 to m[item].Count()-1
                  if i = m[item].Count()-1 then
                        value = value+m[item][i]
                  else
                        value = value+m[item][i]+","
                  end if
            end for 
            result = result + " " +item+"="+value
      end for
      return result
End Function


'*********************************************************
'**
'** Count number of user tokens we have
'**
'*********************************************************
Function oauth_count()
    
      loadItems()
      for each item in m.items
            if m.accessToken.Count() <> m.[item].Count() then
                  print "accessToken / "; item; " counts do not match"
                  return invalid
            end if
      end for
    
      return m.accessToken.Count()

End Function


'*********************************************************
'**
'** create a header object with authorization token
'**
'*********************************************************
Function oauth_sign(userIndex As Integer) as Object 

      ' Save our current selection
      m.currentAccessTokenInd = userIndex
    
      signedHeader = {}
    
      if m.accessToken[userIndex] <> ""
            signedHeader["Authorization"] = "Bearer " + m.accessToken[userIndex]
            print "Creating Signed Headers: "; m.accessToken[userIndex]
      end if
      
      return signedHeader

End Function


sub makeRequest(headers as Object, url as String, method as String, post_params as String, num as Integer)
    print "HelperFunctions [makeRequest]"
    context = createObject("roSGNode", "Node")
    params = {
        headers: headers,
        uri: url,
        method: method,
        params: post_params
    }

    context.addFields({
        parameters: params,
        num: num,
        response: {}
    })

    m.UriHandler.request = { context: context }    
end sub


'******************************************************
'Parse a string into a roXMLElement
'
'return invalid on error, else the xml object
'******************************************************
Function ParseXML(str As String) As dynamic
      if str = invalid return invalid
      xml=CreateObject("roXMLElement")
      if not xml.Parse(str) return invalid
      return xml
End Function


'******************************************************
'isxmlelement
'
'Determine if the given object supports the ifXMLElement interface
'******************************************************
Function isxmlelement(obj as dynamic) As Boolean
      if obj = invalid return false
      if GetInterface(obj, "ifXMLElement") = invalid return false
      return true
End Function