' ********** Copyright 2018 Roku, Inc.  All Rights Reserved. **********
Library "Roku_Ads.brs"

function init()
    '
    '  Following info must be provided
    '   m.top.testConfig.url          :  bootstrap manifest server URL
    '
    m.top.adPlaying = false
    m.top.functionName = "runTask"
end function

function runTask()
    '
    '  1. Load and instanciate Adapter
    '
    adapter = loadAdapter()
    '
    '  2. Request preplay
    '
    loadStream(adapter)
    '
    '  3. Play content
    '
    runLoop(adapter)
end function

function loadAdapter() as object
    '
    '   1. Load and instanciate Adapter
    '
    adapter = RAFX_SSAI({name: "publica"}) 
    if adapter <> invalid
        adapter.init()
        print "RAFX_SSAI version ";adapter["__version__"]
    end if
    return adapter
end function

function loadStream(adapter as object) as void
    if invalid = adapter then return

    print m.top.testConfig.url

    '
    '  2.1 Compose request info
    '
    request = {
        ' Required, masterURL
        url: m.top.testConfig.url,
        kbps: 3000 ' Max kbps to select URL from multiple bit rate streams.
        '  callback : function(m3u8str as string) as string
        '     Write your own stream selector here
        '     return valid_selected_stream_url
        '  end function
    }

    requestResult = adapter.requestStream(request) ' Required
    if requestResult["error"] <> invalid
        print "Error requesting stream ";requestResult
        return
    end if

    '
    '  2.2  Get stream info returned from manifest server
    '
    streamInfo = adapter.getStreamInfo()
    if streamInfo = invalid or streamInfo["error"] <> invalid
        print "error "; streamInfo
        return
    end if
    
    '
    '  2.3  Configure video node
    '
    vidContent = createObject("RoSGNode", "ContentNode")
    vidContent.url = streamInfo.playURL
    vidContent.title = m.top.testConfig.title
    vidContent.streamformat = "hls"
    m.top.video.content = vidContent
    m.top.video.setFocus(true)
    m.top.video.visible = true
    m.top.video.EnableCookies()

    '
    '   2.4  RAF settings
    '
    ' https://developer.roku.com/docs/developer-program/advertising/raf-api.md
    raf = Roku_Ads()

    ' General audience measurment
    raf.enableAdMeasurements(true)
    raf.setContentGenre("Romantic comedy", false)
    raf.setContentId("test")
    raf.setContentLength(300)

    ' Nielsen DAR (Digital Ad Ratings)
    raf.enableNielsenDAR(true)
    raf.setNielsenGenre("GV")
    raf.setNielsenAppId("P2871BBFF-1A28-44AA-AF68-C7DE4B148C32")
    raf.setNielsenProgramId("Movie Title")

    raf.setDebugOutput(true)
end function

function runLoop(adapter as object) as void
    if invalid = adapter then return
    '
    '   3.1  Enable adapter Ad tracking
    '
    port = CreateObject("roMessagePort")
    adapter.enableAds({ player: { sgnode: m.top.video, port: port } })
    '
    '   3.2  set callbacks (optional)
    '
    addCallbacks(adapter) ' optional
    '
    '   3.3  Observe video node
    '
    m.top.video.observeFieldScoped("position", port)
    m.top.video.observeFieldScoped("control", port)
    m.top.video.observeFieldScoped("state", port)
    '
    '   3.4  Start playback
    '
    m.top.video.control = "play"
    while true
        msg = wait(1000, port)
        if type(msg) = "roSGNodeEvent" and msg.getField() = "control" and msg.getNode() = m.top.video.id and not m.top.adPlaying and (msg.getData() = "stop" or msg.getData() = "done") or m.top.video = invalid
            exit while ' video node stopped. quit loop
        end if
        '
        '  3.5  Have adapter handle events
        '
        curAd = adapter.onMessage(msg) ' Required
        if "roSGNodeEvent" = type(msg) and "state" = msg.getField() and "finished" = msg.getData() and msg.getNode() = m.top.video.id then
            exit while ' stream ended. quit loop
        end if
    end while
    m.top.video.unobserveFieldScoped("position")
    m.top.video.unobserveFieldScoped("control")
    m.top.video.unobserveFieldScoped("state")
end function

function addCallbacks(adapter) as void
    adapter.addEventListener(adapter.AdEvent.POD_START, podStartCallback)
    adapter.addEventListener(adapter.AdEvent.IMPRESSION, adEventCallback)
    adapter.addEventListener(adapter.AdEvent.FIRST_QUARTILE, adEventCallback)
    adapter.addEventListener(adapter.AdEvent.MIDPOINT, adEventCallback)
    adapter.addEventListener(adapter.AdEvent.THIRD_QUARTILE, adEventCallback)
    adapter.addEventListener(adapter.AdEvent.COMPLETE, adEventCallback)
    adapter.addEventListener(adapter.AdEvent.POD_END, podEndCallback)

    m.adIndex = 0
    m.COMPLETE = adapter.AdEvent.COMPLETE
end function


' AdEvent.POD_START
function podStartCallback(podInfo as object)
    print "At ";podInfo.position;" from Adapter -- " ; podInfo.event
    if not m.top.adPlaying
        m.top.adPlaying = True
        m.top.video.enableTrickPlay = false
    end if

    if invalid <> podInfo.pod
        adIface = Roku_Ads()
        adIface.fireTrackingEvents(podInfo.pod, { type: podInfo.event })
        m.adIndex = 0
    end if
end function

' AdEvent.POD_END
function podEndCallback(podInfo as object)
    print "At ";podInfo.position;" from Adapter -- " ; podInfo.event
    m.top.adPlaying = false
    m.top.video.enableTrickPlay = true
    m.top.video.setFocus(true)

    if invalid <> podInfo.pod
        adIface = Roku_Ads()
        ' fire Pod pixel
        adIface.fireTrackingEvents(podInfo.pod, { type: podInfo.event })
        m.adIndex = 0
    end if
end function

' AdEvent.IMPRESSION
' AdEvent.FIRST_QUARTILE
' AdEvent.MIDPOINT
' AdEvent.THIRD_QUARTILE
' AdEvent.COMPLETE
function adEventCallback(adInfo as object) as void
    print "At ";adInfo.position;" from Adapter -- " ; adInfo.event
    if invalid <> adInfo.pod and m.adIndex < adInfo.pod.ads.count()
        adIface = Roku_Ads()
        ' fire Ad pixel
        ad = adInfo.pod.ads[m.adIndex]
        adIface.fireTrackingEvents(ad, { type: adInfo.event })

        if adInfo.event = m.COMPLETE
            m.adIndex += 1
        end if
    end if
end function
