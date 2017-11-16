
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
      
      
      