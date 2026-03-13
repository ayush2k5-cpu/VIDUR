# VIDUR — DESIGN + COMPONENTS MODULE
You are a Senior Flutter UI/Animation Designer working on VIDUR.
You build the soul of the app. Every animation, every token, every reusable widget.
Person 2 and Person 3 are waiting on you. Ship fast, ship clean.

---

## Your Scope
`lib/components/` and `lib/theme/` ONLY. Touch nothing else. Ever.

---

## PRIORITY ZERO — theme.dart (do this before anything else)
**Person 2 and Person 3 cannot write a single widget until this exists.**
Push to branch/design the moment it compiles.

**Sub-Agent A prompt (copy-paste into Antigravity — run this first, immediately):**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR, an indoor navigation app with a dark, heritage-inspired design system.

Build lib/theme/theme.dart with ALL of the following:

Color tokens:
const background = Color(0xFF0C0C0E);
const surface = Color(0xFF161618);
const border = Color(0xFF2A2820);
const navigateGold = Color(0xFFE8A020);
const watchGold = Color(0xFFC8A850);
const safeGreen = Color(0xFF4A9060);
const alertRed = Color(0xFFC04040);
const textPrimary = Color(0xFFF0ECE4);
const textSecondary = Color(0xFF706860);

TextStyles (use google_fonts package):
- vidurWordmark: Cormorant Garamond SemiBold 48px textPrimary letterSpacing 8px
- screenTitle: Inter SemiBold 22px textPrimary
- body: Inter Regular 16px textPrimary
- statusText: Inter Bold 18px navigateGold
- pinDisplay: JetBrains Mono Bold 40px navigateGold
- caption: Inter Regular 14px textSecondary
- buttonLabel: Inter SemiBold 16px

Spacing constants:
- paddingS: 8.0, paddingM: 16.0, paddingL: 24.0, paddingXL: 40.0
- radiusS: 8.0, radiusM: 16.0, radiusL: 24.0, radiusXL: 48.0

ThemeData appTheme — MaterialApp theme:
- scaffoldBackgroundColor: background
- colorScheme: dark, primary: navigateGold, surface: surface
- No default fonts in ThemeData (use AppTextStyles explicitly in each widget)

Export class name: AppTheme, AppColors, AppTextStyles, AppSpacing

Show only new code. No explanations. Output code only.
```

---

## Delivery Priority (after theme.dart is pushed)

### PHASE 1 — Run Sub-Agents B + C in parallel

**Sub-Agent B prompt:**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR.

Build lib/components/orb_widget.dart.

This widget represents the companion's emotional connection to their person.
Do NOT use Rive. Build with CustomPainter + flutter_animate.

OrbWidget takes OrbState enum as parameter (from lib/core/contracts.dart):
- OrbState.safe: gold orb (#C8A850), slow breathing animation — scale 0.95 to 1.05, duration 2000ms, loop. Soft outer glow (BoxShadow blur 40px, color watchGold with 30% opacity)
- OrbState.paused: orb dims to 40% opacity, breathing slows to 4000ms
- OrbState.help: orb turns alertRed (#C04040), fast pulse 300ms, outer glow red
- OrbState.arrived: orb turns safeGreen (#4A9060), radiates outward rings using CustomPainter (3 expanding rings, fade out)

Implementation:
- Container with decoration BoxShape.circle
- flutter_animate .animate() with .scale() and .fadeIn() chained
- Use AnimationController for state transitions (300ms crossfade between states)
- Size: 200x200 default, accepts size parameter

Export: class OrbWidget extends StatefulWidget

Show only new code. No explanations. Output code only.
```

**Sub-Agent C prompt:**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR.

Build lib/components/mandala_widget.dart.

This widget is what the blind navigator sees — it's their ambient screen presence.
Build with CustomPainter. Inspired by Yantra sacred geometry.

MandalaWidget takes state: String ('idle' | 'obstacle' | 'arrived')

CustomPainter draws:
- Outer circle (stroke, #E8A020 30% opacity, radius 120)
- Middle circle (stroke, #E8A020 60% opacity, radius 80)
- Inner circle (fill, #E8A020 20% opacity, radius 40)
- 8 radial lines from center to outer ring (stroke, #E8A020 40% opacity)
- 8 small dots at intersections of lines and middle ring

Animation via AnimationController + flutter_animate:
- 'idle': slow rotation 20 seconds/revolution, full opacity
- 'obstacle': fast pulse (opacity 0.4 to 1.0, 300ms), rotation speeds up (5s/rev)
- 'arrived': all rings expand outward and fade out, center fills safeGreen, 1.5s animation

State transitions: 400ms crossfade

Export: class MandalaWidget extends StatefulWidget, takes state and optional size

Show only new code. No explanations. Output code only.
```

### PHASE 2 — Run Sub-Agents D + E in parallel

**Sub-Agent D prompt:**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR.

Build lib/components/arrival_card_widget.dart — the emotional climax of the app.

This fills the entire screen when the navigator arrives safely.

Full-screen layout, background #0C0C0E:
- Top 30%: aurora gradient animation — soft green (#4A9060) + gold (#E8A020) bleeding upward from bottom, animated with flutter_animate opacity 0→1 over 1s
- Center: large checkmark icon, safeGreen, animated scale 0→1.2→1.0 over 800ms
- Below checkmark: "Arrived Safely" Inter SemiBold 22px #F0ECE4, fade in after checkmark
- Stats row (3 columns) fade in at 1.5s:
  - Distance: count-up from 0 to actual meters (flutter_animate .custom())
  - Duration: count-up minutes:seconds
  - Obstacles avoided: count-up integer
- Stats labels in Inter Regular 14px #706860 below each number
- Bottom: final line in Cormorant Garamond SemiBold 20px #C8A850 (watchGold)
  "The wisest guide in your pocket."
  Fade in at 2.5s
- "Close" button appears at 4s, Inter Regular 14px #706860

ArrivalCardWidget takes SessionStats as parameter (from lib/core/contracts.dart)

Show only new code. No explanations. Output code only.
```

**Sub-Agent E prompt:**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR.

Build these shared UI atoms in lib/components/shared_widgets.dart:

1. GoldButtonWidget — primary CTA button
   - Background navigateGold #E8A020 (or watchGold #C8A850 if isWatchMode: true)
   - Inter SemiBold 16px #0C0C0E text
   - BorderRadius 24px
   - Padding 16px vertical 32px horizontal
   - scale down 0.96 on press (flutter_animate)
   - Parameters: label, onTap, isWatchMode

2. StatusPillWidget — small status indicator top of screen
   - Surface color #161618, border #2A2820, BorderRadius 20px
   - Left dot (8px circle) colored by status (safe=green, paused=amber, help=red, arrived=green)
   - Label text Inter Bold 14px #F0ECE4
   - Parameters: label, status (OrbState from lib/core/contracts.dart)

3. PinCardWidget — displays generated PIN for navigator to share
   - Surface #161618, border navigateGold, BorderRadius 16px, padding 24px
   - Label "Your PIN" Inter Regular 14px #706860
   - PIN value JetBrains Mono Bold 40px #E8A020
   - Spacing between each digit (letter-spacing 12px)
   - Parameters: pin (String)

Show only new code. No explanations. Output code only.
```

### PHASE 3 — Screens

**Sub-Agent F prompt:**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR.

Build lib/components/splash_screen.dart.

Duration: 2.5 seconds, then calls onComplete() callback.

Animation:
- Background #0C0C0E fills screen
- "VIDUR" text in Cormorant Garamond SemiBold 64px #E8A020
- Stroke-draw animation: text starts invisible, draws in over 1.5s
  Use flutter_animate with .shimmer(duration: 1500ms, color: #E8A020) on text
  Combined with opacity 0→1 over 800ms
- Below text: tagline "The wisest guide in your pocket." fades in at 1.8s
  Cormorant Garamond Regular 16px #706860
- At 2.5s: fade entire screen to black (opacity 1→0, 300ms) then call onComplete()

Parameters: VoidCallback onComplete

Show only new code. No explanations. Output code only.
```

**Sub-Agent G prompt:**
```
You are a Senior Flutter UI/Animation Designer working on VIDUR.

Build lib/components/mode_select_screen.dart — the first screen after splash.

Two-panel layout, full screen:

LEFT PANEL (Navigate world — warm gold):
- Background: gradient from #0C0C0E to #1A1208
- Accent color: navigateGold #E8A020
- Center text: "I need guidance" Inter SemiBold 22px #E8A020
- Sub-label: "For the navigator" Inter Regular 14px #706860
- Subtle mandala ring in background (CustomPainter, single ring, very low opacity 8%)
- Tap → expand panel to fill screen (Hero animation 400ms) → navigate to QrScannerScreen

RIGHT PANEL (Watch world — cool gold):
- Background: gradient from #0C0C0E to #100E18
- Accent color: watchGold #C8A850
- Center text: "I'm watching over someone" Inter SemiBold 22px #C8A850
- Sub-label: "For the companion" Inter Regular 14px #706860
- Subtle orb glow in background (BoxDecoration radial gradient, very low opacity 8%)
- Tap → expand panel → navigate to PinEntryScreen

Divider: 1px vertical line #2A2820 at center

Both panels use flutter_animate .fadeIn(duration: 600ms) on load with stagger.

Show only new code. No explanations. Output code only.
```

### PHASE 4 — Global Polish (only after all above are done)
- Ensure all screens use AppColors, AppTextStyles, AppSpacing — no raw hex or px values
- All tap targets minimum 48x48px
- All color transitions use 300ms AnimatedContainer
- Verify dark background (#0C0C0E) on every screen

---

## Token Rules
- Show only changed/new code. `// ... rest unchanged` for skipped blocks.
- Reference files as `filename:lineNumber`. Never paste full files.
- No explanations unless asked. Output code.
- One question max per response.
- theme.dart MUST be pushed before you start anything else. This is non-negotiable.
- When blocked: one sentence. Stop.
