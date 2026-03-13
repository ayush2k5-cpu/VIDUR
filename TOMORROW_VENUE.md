# VIDUR — VENUE SETUP (TOMORROW MORNING)
## Time budget: arrive by 8:00 AM. Demo at 3:00 PM. You have 5 hours.

---

## BEFORE LEAVING HOME (tonight / early morning)
- [ ] Final `flutter build apk` — confirm APK installs cleanly on demo device
- [ ] Pre-load Mappedin Maker in browser, login confirmed
- [ ] Print 6 QR codes (see QR content format below)
- [ ] Tape + scissors in bag
- [ ] 3 Android phones fully charged — these become your WiFi hotspot anchors
- [ ] Portable chargers for those 3 phones (they must stay plugged in all day)
- [ ] Demo device (your phone) charged to 100%

---

## QR CODE FORMAT
Each QR encodes this JSON string (generate with any QR generator):
```json
{"venueId":"bmsce_001","waypointId":"waypoint_entrance","venueMapUrl":"local"}
```
Print one for each waypoint:
```
QR_01: waypointId = "waypoint_entrance"
QR_02: waypointId = "waypoint_junction_a"
QR_03: waypointId = "waypoint_junction_b"
QR_04: waypointId = "waypoint_hanging_001"   ← hanging obstacle waypoint
QR_05: waypointId = "waypoint_junction_c"
QR_06: waypointId = "waypoint_destination"
```

---

## AT BMSCE — Step-by-Step (8:00 AM)

### 8:00–8:15 — Scout and Map the Demo Route
- Walk the route from demo start point to destination
- Identify the 6 key junctions along the path
- Keep total route under 60 seconds of walking
- The hanging obstacle waypoint (QR_04) should be somewhere mid-route with head-height clearance

### 8:15–8:25 — Place 3 Hotspot Phones as WiFi Anchors
- Turn on hotspot on each phone (use these names: `VIDUR_A`, `VIDUR_B`, `VIDUR_C`)
- Place them at 3 corners/edges of the demo area
- Plug each into a portable charger — they cannot move for the rest of the day
- Note their physical positions on a sketch — you need this for fingerprinting

### 8:25–8:50 — Collect WiFi Fingerprints at 6 Waypoints
At each waypoint, scan all visible WiFi networks and record RSSI:
```bash
# On demo device, use the VIDUR app's built-in fingerprint collector
# (build this into lib/engine/fingerprint_collector_screen.dart tonight)
# OR manually record: open WiFi settings, note signal strength for VIDUR_A, VIDUR_B, VIDUR_C
```
Save as `assets/venue/fingerprints.json`:
```json
{
  "waypoints": [
    {
      "id": "waypoint_entrance",
      "x": 0.0, "y": 0.0, "floor": 0,
      "rssi": { "VIDUR_A": -55, "VIDUR_B": -72, "VIDUR_C": -80 }
    }
  ]
}
```
Record actual RSSI values at each of the 6 waypoints.

### 8:50–9:10 — Place and Test QR Codes
- Tape each QR code at chest height at its waypoint
- Scan each one with the app and confirm correct waypointId is parsed
- Walk the full route once end-to-end as a sanity check

### 9:10–9:30 — Swap Mock for Real Engine
On branch/engine:
- Replace `MockPositionService` with `FusedPositionService` in the Riverpod provider
- Load `assets/venue/fingerprints.json` into `WifiFingerprintService`
- Load `assets/venue/venue_map.json` with the real waypoint coordinates

### 9:30–10:00 — Full Flow Smoke Test
Run complete demo flow:
- [ ] Navigator scans entrance QR → session created → PIN displayed
- [ ] Companion enters PIN → Watch screen shows orb + map
- [ ] Navigator speaks destination → guidance starts
- [ ] Walk 3 waypoints → position updates on companion map
- [ ] Trigger hanging obstacle waypoint → haptic + voice + companion map icon
- [ ] Walk to destination → arrival card shows on both devices
- [ ] Guardian Peek test → video streams in PiP

### 10:00–3:00 PM — Buffer + Polish
- Fix any issues found in smoke test
- Keep demo device on airplane mode with personal hotspots only (eliminates WiFi noise)
- Rehearse the demo narration

---

## DEMO SCRIPT (2-minute pitch)
1. "VIDUR. Named after the wisest counselor in the Mahabharata."
2. Show Navigator side: QR scan → PIN → voice destination input
3. Walk the route → binaural audio plays
4. Show Companion side simultaneously (second person holds Watch device)
5. Trigger hanging obstacle → "Caution. Hanging obstacle at head height."
6. Arrive → both devices show Arrival Card
7. "Zero hardware. Existing WiFi. 45 minutes to set up any venue."

---

## EMERGENCY FALLBACKS
| Problem | Fallback |
|---|---|
| WiFi fingerprinting inaccurate | Disable WiFi layer, run QR + PDR only |
| QR scanner not detecting | Increase brightness, move QR to flat surface |
| Agora video fails | Skip Guardian Peek in demo, mention it verbally |
| Firebase connection drops | Pre-load session data, demo UI only |
| Demo device crashes | Have APK on second phone as backup |

---

## DO NOT DO AT VENUE
- Do not run `flutter pub get` at venue (slow internet)
- Do not push new code during demo (git conflicts risk)
- Do not use venue WiFi for fingerprinting (use your 3 hotspot phones only)
