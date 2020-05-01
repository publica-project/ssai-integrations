# Roku-Publica SSAI Adapter

Test Roku application showing how to integrate RAF (Roku Ad Framework) with Publica SSAI server.

## Integration entry point

`components/PublicaTask.brs` -> `runTask()`

## How to test

[Developer environment setup](https://developer.roku.com/docs/developer-program/getting-started/developer-setup.md)

Zip up the roku app:
  - `assets/`
  - `components/`
  - `images/`
  - `lib/`
  - `source/`
  - `manifest`

Then upload the archive to your Roku device.

Run `telnet <roku-device-ip> 8085` to access the debugger.

## Sample RAF debug output

```
------ Running dev 'Publica SSAI' main ------

[RAF] Roku_Ads Framework version 2.1231
RAFX_SSAI version 0.0.1
05-01 21:11:50.429 [beacon.signal] |VODStartInitiate ----------> TimeBase(9976 ms)
05-01 21:11:50.429 [beacon.signal] |VODStartComplete ----------> Duration(3364 ms), 1.72 KiP
At  0.033  from Adapter -- PodStart

[RAF] fireTrackingEvents(..., {"type":"PodStart"})
At  0.033  from Adapter -- Impression

[RAF] fireTrackingEvents(..., {"type":"Impression"})

[RAF] setRIDAInterface("device")
At  4.05  from Adapter -- FirstQuartile

[RAF] fireTrackingEvents(..., {"type":"FirstQuartile"})
At  12.038  from Adapter -- Midpoint

[RAF] fireTrackingEvents(..., {"type":"Midpoint"})
At  20.048  from Adapter -- ThirdQuartile

[RAF] fireTrackingEvents(..., {"type":"ThirdQuartile"})
At  28.036  from Adapter -- Complete

[RAF] fireTrackingEvents(..., {"type":"Complete"})
At  28.036  from Adapter -- PodComplete

[RAF] fireTrackingEvents(..., {"type":"PodComplete"})