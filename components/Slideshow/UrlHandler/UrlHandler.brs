'*************************************************************
'** PhotoView for Google Photos
'** Copyright (c) 2017-2018 Chris Taylor.  All rights reserved.
'** Use of code within this application subject to the MIT License (MIT)
'** https://raw.githubusercontent.com/chtaylo2/Roku-GooglePhotos/master/LICENSE
'*************************************************************

Sub init()
    print "UrlHandler.brs - [init]"
    m.port = createObject("roMessagePort")
    m.top.observeField("request", m.port)
    m.top.functionName = "go"
    m.top.control = "RUN"
End Sub


Sub go()
    print "UrlHandler.brs - [go]"
    ' Holds requests by id
    m.jobsById = {}
    ' UriFetcher event loop
    
    while true
        msg = wait(0, m.port)
        mt = type(msg)
        print "--------------------------------------------------------------------------"
        print "Received event type '"; mt; "'"
        ' If a request was made
        if mt = "roSGNodeEvent"
            if msg.getField()="request"
                if addRequest(msg.getData()) <> true then print "Invalid request"
            else if msg.getField()="encodeRequest"
                if encodeRequest(msg.getData()) <> true then print "Invalid request"
            else if msg.getField()="ContentCache"
                updateContent()
            else
                print "Error: unrecognized field '"; msg.getField() ; "'"
            end if
        ' If a response was received
        else if mt="roUrlEvent"
            processResponse(msg)
            ' Handle unexpected cases
        else
            print "Error: unrecognized event type '"; mt ; "'"
        end if
  end while
  
End Sub


Function addRequest(request as Object) as Boolean
    print "UrlHandler.brs - [addRequest]"
    if type(request) = "roAssociativeArray"
        context = request.context
        if type(context) = "roSGNode"
            parameters = context.parameters
            if type(parameters)="roAssociativeArray"
                headers = parameters.headers
                method = parameters.method
                uri = parameters.uri
                params = parameters.params

                if type(uri) = "roString"
                    urlXfer = createObject("roUrlTransfer")
                    urlXfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
                    urlXfer.InitClientCertificates()
                    urlXfer.setUrl(uri)
                    urlXfer.setPort(m.port)
                    ' Add headers to the request
                    
                    for each header in headers
                        urlXfer.AddHeader(header, headers.lookup(header))
                    end for
                    
                    ' should transfer more stuff from parameters to urlXfer
                    idKey = stri(urlXfer.getIdentity()).trim()
                    ' Make request based on request method
                    ' AsyncGetToString returns false if the request couldn't be issued
                    if method = "POST" or method = "PUT" or method = "DELETE"
                        urlXfer.setRequest(method)
                        ok = urlXfer.AsyncPostFromString(params)
                    else
                        ok = urlXfer.AsyncGetToString()
                    end if
              
                    if ok then
                        m.jobsById[idKey] = {
                            context: request,
                            xfer: urlXfer
                        }
                    else
                        print "Error: request couldn't be issued"
                    end if
                    print "Initiating transfer '"; idkey; "' for URI '"; uri; "'"; " succeeded: "; ok
                    
                else
                    print "Error: invalid uri: "; uri
                    m.top.numBadRequests++
                end if
            else
                print "Error: parameters is the wrong type: " + type(parameters)
                return false
            end if
        else
            print "Error: context is the wrong type: " + type(context)
            return false
        end if
    else
        print "Error: request is the wrong type: " + type(request)
        return false
    end if
    print "--------------------------------------------------------------------------"
    return true
End Function

Sub processResponse(msg as Object)
    print "UrlHandler.brs - [processResponse]"
    idKey = stri(msg.GetSourceIdentity()).trim()
    job = m.jobsById[idKey]
    if job <> invalid
        context = job.context
        parameters = context.context.parameters
        jobnum = job.context.context.num
        post_data = job.context.context.post_data
        uri = parameters.uri
        print "Response for transfer '"; idkey; "' for URI '"; uri; "'"
        result = {
            code:        msg.GetResponseCode(),
            headers:     msg.GetResponseHeaders(),
            content:     msg.GetString(),
            error:       msg.GetFailureReason(),
            post_data:   post_data
            num:         jobnum
        }
        'print "URL RESULT: ";  result
        'print "MSG: "; msg
    
        ' could handle various error codes, retry, etc. here
        m.jobsById.delete(idKey)
        job.context.context.response = result
        if result.num = 0
            m.top.albumList = job.context.context.response
        else if result.num = 1
            m.top.albumImages = job.context.context.response
        else if result.num = 2
            m.top.refreshToken = job.context.context.response
        end if
    else
        print "Error: event for unknown job "; idkey
    end if
    print "--------------------------------------------------------------------------"
End Sub


Sub provideResponse(job as object)
    print "UrlHandler.brs - [parseGenToken]"
    result = job.context.context.response
    m.top.response = result
End Sub
