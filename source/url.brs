
REM ******************************************************
REM
REM Url Query builder
REM
REM To aid in percent-encoding url query parameters.
REM In theory you can blindly encode the whole query (including ='s, &'s, etc)
REM
REM so this is a quick and dirty name/value encoder/accumulator
REM
REM The oauth protocol needs to interact with parameters in a
REM particular way, so access to groups of parameters and
REM their encodings are provided as well.
REM
REM Several callbacks can be placed on the returned http object
REM by the calling code to be called by this code when appropriate:
REM callbackPrep - called right before sending
REM callbackRetry - called after failure if retries>0
REM callbackCancel - called after failure if retries=0
REM These allow side effects without explicitly coding them here.
REM ******************************************************

Function NewHttp(url As String, port=invalid As Dynamic, method="GET" As String) as Object
    this                           = CreateObject("roAssociativeArray")
    this.port                      = port 
    this.method                    = method
    this.anchor                    = ""
    this.label                     = "init"
    this.timeout                   = 5000 ' 5 secs
    this.retries                   = 1
    this.status                    = 0
    this.failureReason             = ""
    this.timer                     = CreateObject("roTimespan")
    this.timestamp                 = CreateObject("roTimespan")
    this.headersAA                 = CreateObject("roAssociativeArray")

    'computed accessors
    this.Parse                     = http_parse
    this.AddHeader                 = http_add_header
    this.AddParam                  = http_add_param
    this.AddAllParams              = http_add_all_param
    this.RemoveParam               = http_remove_param
    this.GetURL                    = http_get_url
    this.GetParams                 = http_get_params
    this.ParamGroup                = http_get_param_group

    'transfers
    this.GetToStringWithRetry      = http_get_to_string_with_retry
    this.GetToStringWithTimeout    = http_get_to_string_with_timeout
    this.PostFromStringWithTimeout = http_post_from_string_with_timeout

    this.Go                        = http_go
    this.Ok                        = http_ok
    this.Sync                      = http_sync
    this.Receive                   = http_receive
    this.Cancel                    = http_cancel
    this.CheckTimeout              = http_check_timeout
    this.Retry                     = http_retry

    'internal
    this.Prep                      = http_prep
    this.Wait                      = http_wait_with_timeout
    this.Dump                      = http_dump
    this.GetResponseCode           = http_get_response_code
    this.GetFailureReason          = http_get_failure_reason

    this.Parse(url)

    return this
End Function

Function http_get_response_code() As Integer
    return m.status
End Function

Function http_get_failure_reason() As String
    return m.failureReason
End Function

REM ******************************************************
REM
REM Setup the underlying http transfer object.
REM
REM ******************************************************

Function http_prep(method="" As String)
    ' this callback allows just-before-send
    ' mods to the request, e.g. timestamp
    if isfunc(m.callbackPrep) then m.callbackPrep()
    m.status  = 0
    m.failureCode = 0
    m.failureReason = ""
    m.response = ""
    urlobj = CreateObject("roUrlTransfer")
    if type(m.port)<>"roMessagePort" then m.port = CreateObject("roMessagePort")
    urlobj.SetPort(m.port)
    urlobj.SetCertificatesFile("common:/certs/ca-bundle.crt")
    urlobj.InitClientCertificates()
    urlobj.EnableEncodings(true)
    for each header in m.headersAA
        urlobj.AddHeader(header,m.headersAA[header])
    end for
    url = m.GetUrl()
    urlobj.SetUrl(url)
    if m.method<>"" and m.method<>method then urlobj.SetRequest(m.method)
    HttpActive().replace(m,urlobj)
    m.timer.mark()
End Function

REM ******************************************************
REM
REM Parse an url string into components of this object
REM
REM ******************************************************

Function http_parse(url As String) as Void
    remnant = CreateObject("roString")
    remnant.SetString(url)

    anchorBegin = Instr(1, remnant, "#")
    if anchorBegin>0
        if anchorBegin<Len(remnant) then m.anchor = Mid(remnant,anchorBegin+1)
        remnant = Left(remnant,anchorbegin-1)
    end if

    paramBegin = Instr(1, remnant, "?")
    if paramBegin > 0
        if paramBegin < Len(remnant) then m.GetParams("urlParams").parse(Mid(remnant,paramBegin+1))
        remnant = Left(remnant,paramBegin-1)
    end if

    m.base = remnant
End Function

REM ******************************************************
REM
REM Add an HTTP header to this object
REM
REM ******************************************************

Function http_add_header(headerName As String, headerValue As String)
    m.headersAA [headerName] = headerValue
End Function

REM ******************************************************
REM
REM Add an URL parameter to this object
REM
REM ******************************************************

Function http_add_param(name As String, val As String, group="" As String)
    params = m.GetParams(group)
    params.add(name,val)
End Function


Function http_add_all_param(keys as object, vals as object, group="" As String)
    params = m.GetParams(group)
    params.addall(keys,vals)
End Function

REM ******************************************************
REM
REM Remove an URL parameter from this object
REM
REM ******************************************************

Function http_remove_param(name As String, group="" As String)
    params = m.GetParams(group)
    params.remove(name)
End Function

REM ******************************************************
REM
REM Get a named parameter list from this object
REM
REM ******************************************************

Function http_get_params(group="" As String)
    name = m.ParamGroup(group)
    if not m.DoesExist(name) then m[name] = NewUrlParams()
    return m[name]
End Function

REM ******************************************************
REM
REM Return the full encoded URL.
REM
REM ******************************************************

Function http_get_url() As String
    url = m.base
    params = m.GetParams("urlParams")
    if not params.empty() then url = url + "?"
    url = url + params.encode()
    if m.anchor <> "" then url = url + "#" + m.anchor
    return url
End Function

REM ******************************************************
REM
REM Return the parameter group name,
REM correctly defaulted if necessary.
REM
REM ******************************************************

Function http_get_param_group(group="" as String)
    if group = ""
        if m.method="POST"
            name = "bodyParams"
        else
            name = "urlParams"
        end if
    else
        name = group
    end if
    return name
End Function

REM ******************************************************
REM
REM Performs Http.AsyncGetToString() in a retry loop
REM with exponential backoff. To the outside
REM world this appears as a synchronous API.
REM
REM Return empty string on timeout
REM
REM ******************************************************

Function http_get_to_string_with_retry() as String

    timeout%         = 2
    num_retries%     = 5

    while num_retries% > 0
        ' print "Http: get tries left " + itostr(num_retries%)
        m.Prep("GET")
        if (m.Http.AsyncGetToString())
            if m.Wait(timeout%) then exit while
            timeout% = 2 * timeout%
        endif
        num_retries% = num_retries% - 1
    end while

    return m.response
End Function

REM ******************************************************
REM
REM Performs Http.AsyncGetToString() with a single timeout in seconds
REM To the outside world this appears as a synchronous API.
REM
REM Return empty string on timeout
REM
REM ******************************************************

Function http_get_to_string_with_timeout(seconds as Integer) as String
    m.Prep("GET")
    if (m.Http.AsyncGetToString()) then m.Wait(seconds)
    return m.response
End Function

REM ******************************************************
REM
REM Performs Http.AsyncPostFromString() with a single timeout in seconds
REM To the outside world this appears as a synchronous API.
REM
REM Return empty string on timeout
REM
REM ******************************************************

Function http_post_from_string_with_timeout(val As String, seconds as Integer) as String
    m.Prep("POST")
    if (m.Http.AsyncPostFromString(val)) then m.Wait(seconds)
    return m.response
End Function

REM ******************************************************
REM
REM Common wait() for all the synchronous http transfers
REM
REM ******************************************************

Function http_wait_with_timeout(seconds As Integer) As Boolean
    id = HttpActive().ID(m)
    while m.status=0
        nextTimeout = 1000 * seconds - m.timer.TotalMilliseconds()
        if seconds>0 and nextTimeout<=0 then exit while
        event = wait(nextTimeout, m.Http.GetPort())
        if type(event) = "roUrlEvent"
            HttpActive().receive(event)
        else if event = invalid
            m.cancel()
        else
            print "Http: unhandled event "; type(event)
        endif
    end while
    HttpActive().removeID(id)
    m.Dump()
    return m.Ok()
End Function

Function http_receive(msg As Object)
    m.status = msg.GetResponseCode()
    m.failureReason = msg.GetFailureReason()
    m.response = msg.GetString()
    m.label = "done"
End Function

Function http_cancel()
    m.Http.AsyncCancel()
    m.status = -1
    m.label = "cancel"
    m.dump()
    HttpActive().remove(m)
End Function

Function http_go(method="" As String) As Boolean
    ok = false
    m.Prep(method)
    if m.method="POST" or m.method="PUT"
        ok = m.http.AsyncPostFromString(m.getParams().encode())
    else if m.method="GET" or m.method="DELETE" or m.method=""
        ok = m.http.AsyncGetToString()
    else
        print "Http: "; m.method; " is not supported"
    end if
    m.label = "sent"
    'm.Dump()
    return ok
End Function

Function http_ok() As Boolean
    ' depends on m.status which is updated by m.Wait()
    statusGroup = int(m.status/100)
    return statusGroup=2 or statusGroup=3
End Function

Function http_sync(seconds As Integer) As Boolean
    if m.Go() then m.Wait(seconds)
    return m.Ok()
End Function

Function http_dump()
    time = "unknown"
    if m.DoesExist("timer") then time = itostr(m.timer.TotalMilliseconds())
    print "Http: #"; m.Http.GetIdentity(); " "; m.label; " status:"; m.status; " time: "; time; "ms request: "; m.method; " "; m.Http.GetURL()
    if not m.GetParams("bodyParams").empty() then print "  body: "; m.GetParams("bodyParams").encode()
End Function

Function http_check_timeout(defaultTimeout=0 As Integer) As Integer
    timeLeft = m.timeout-m.timer.TotalMilliseconds()
    if timeLeft<=0
        m.retry()
        timeLeft = defaultTimeout
    end if
    return timeLeft
End Function

Function http_retry(defaultTimeout=0 As Integer) As Integer
    m.cancel()
    if m.retries>0
        m.retries = m.retries - 1
        if isfunc(m.callbackRetry) then m.callbackRetry() else m.go()
    else if isfunc(m.callbackCancel)
        m.callbackCancel()
    end if
End Function

REM ******************************************************
REM
REM Operations on a collection of URL parameters
REM
REM ******************************************************

Function NewUrlParams(encoded="" As String, separator="&" As String) As Object
    'stores the unencoded parameters in sorted order
    this                           = CreateObject("roAssociativeArray")
    this.names                     = CreateObject("roArray",0,true)
    this.params                    = CreateObject("roAssociativeArray")
    this.params.SetModeCaseSensitive()

    this.encode                    = params_encode
    this.parse                     = params_parse
    this.add                       = params_add
    this.addReplace                = params_add_replace
    this.addAll                    = params_add_all
    this.remove                    = params_remove
    this.empty                     = params_empty
    this.get                       = params_get
    this.separator                 = separator
    this.parse(encoded)
    return this
End Function

Function params_encode() As String
    encodedParams = ""
    m.names.reset()
    while m.names.isNext()
        name = m.names.Next()
        encodedParams = encodedParams + URLEncode(name) + "=" + URLEncode(m.params[name])
        if m.names.isNext() then encodedParams = encodedParams + m.separator
    end while
    return encodedParams
End Function

Function params_parse(encoded_params As String) as Object
    params = strTokenize(encoded_params,m.separator)
    for each paramExpr in params
        param = strTokenize(paramExpr,"=")
        if param.Count()=2 then m.addReplace(UrlDecode(param[0]),UrlDecode(param[1]))
    end for
    return m
End Function

Function params_add(name As String, val As String) as Object
    if not m.params.DoesExist(name)
        SortedInsert(m.names, name)
        m.params[name] = val
    end if
    return m
End Function

Function params_add_replace(name As String, val As String) as Object
    if m.params.DoesExist(name)
        m.params[name] = val
    else
        m.add(name,val)
    end if
    return m
End Function

Function params_add_all(keys as Object, vals as object) as Object
' keys is an array
' vals is an array
    i = 0
    for each name in keys
        if not m.params.DoesExist(name) then m.names.push(name)
        m.params[name] = vals[i]
        i = i + 1
    end for
    QuickSort(m.names)
    return m
End Function

sub params_remove(name As String)
    if m.params.delete(name)
        n = 0
        while n<m.names.count()
            if name=m.names[n]
                m.names.delete(n)
                return
            endif
            n = n + 1
        end while
    endif
End sub

Function params_empty() as Boolean
    return (m.params.IsEmpty())
End Function

Function params_get(name As String) as String
    return validstr(m.params[name])
End Function


REM ******************************************************
REM
REM URLEncode - strict URL encoding of a string
REM
REM ******************************************************

Function URLEncode(str As String) As String
    if not m.DoesExist("encodeProxyUrl") then m.encodeProxyUrl = CreateObject("roUrlTransfer")
    return m.encodeProxyUrl.urlEncode(str)
End Function

REM ******************************************************
REM
REM URLDecode - strict URL decoding of a string
REM
REM ******************************************************

Function URLDecode(str As String) As String
    strReplace(str,"+"," ") ' backward compatibility
    if not m.DoesExist("encodeProxyUrl") then m.encodeProxyUrl = CreateObject("roUrlTransfer")
    return m.encodeProxyUrl.Unescape(str)
End Function

'
' map of identity to active http objects
'
Function HttpActive() As Object
    ' singleton factory
    ha = m.HttpActive
    if ha=invalid
        ha = CreateObject("roAssociativeArray")
        ha.actives  = CreateObject("roAssociativeArray")
        ha.icount   = 0
        ha.defaultTimeout = 30000 ' 30 secs
        ha.checkTimeouts  = http_active_checkTimeouts
        ha.count    = http_active_count
        ha.receive  = http_active_receive
        ' by http obj
        ha.id       = http_active_id
        ha.add      = http_active_add
        ha.remove   = http_active_remove
        ha.replace  = http_active_replace
        ' by ID
        ha.getID    = http_active_getID
        ha.removeID = http_active_removeID
        ha.total    = strtoi(validstr(RegRead("Http.total","Debug")))
        m.HttpActive = ha
    end if
    return ha    
End Function

Function http_active_count() As Dynamic
    return m.icount
End Function

Function http_active_receive(msg As Object) As Dynamic
    id = msg.GetSourceIdentity()
    http = m.getID(id)
    if http<>invalid
        http.receive(msg)
    else
        print "Http: #"; id; " discarding unidentifiable http response"
        print "Http: #"; id; " status"; msg.GetResponseCode()
        print "Http: #"; id; " response"; chr(10); msg.GetString()
    end if
    return http
end Function

Function http_active_id(http As Object) As Dynamic
    id = invalid
    if http.DoesExist("http")
        id = http.http.GetIdentity()
    end if
    'print "Http: got identity #"; id
    return id
End Function

Function http_active_add(http As Object)
    id = m.ID(http)
    if id<>invalid
        'print "Http: #"; id; " adding to active"
        m.actives[itostr(id)] = http
        m.icount = m.icount + 1
        m.total = m.total + 1
        if wrap(m.total,50)=0
            RegWrite("Http.total",itostr(m.total),"Debug")
            print "Http: total requests"; m.total
        end if
    end if
End Function

Function http_active_remove(http As Object)
    id = m.ID(http)
    if id<>invalid then m.removeID(id)
End Function

Function http_active_replace(http As Object, urlXfer As Object)
    m.remove(http)
    http.http = urlXfer
    m.add(http)
End Function

Function http_active_getID(id As Integer) As Dynamic
    return m.actives[itostr(id)]
End Function

Function http_active_removeID(id As Integer)
    strID = itostr(id)
    if m.actives.DoesExist(strID)
        'print "Http: #"; id; " removing from active"
        m.actives.delete(strID)
        m.icount = m.icount -1
    end if
End Function

Function http_active_checkTimeouts() As Integer
    defaultTimeout = m.defaultTimeout
    timeLeft = defaultTimeout
    for each id in m.actives
        active = m.actives[id]
        activeTL = active.checkTimeout(defaultTimeout)
        if activeTL<timeLeft then timeLeft = activeTL
    end for
    return timeLeft
End Function

