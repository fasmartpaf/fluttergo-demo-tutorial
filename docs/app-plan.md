# FlutterGo Demo Tutorial

## Concept
A clear morning desk for daily habits. People open it to tick today's rituals and watch a day ring fill. Local mock data only — no backend.

## Design direction

| Axis | Choice | Why |
|------|--------|-----|
| Palette | Mist dawn `#E8F1F4` background, white surface, leaf green `#2A9B6A` primary, soft citrus `#F3C96B` secondary, deep ink `#14201C` | Fresh instructional morning — differs from Ember charcoal/coral, Lane amber sidewalk, Vitrine chalk/indigo |
| Type | Sora (display) + Plus Jakarta Sans (UI) | Clear demo typography; not Fraunces/Outfit, Barlow/Figtree, or Newsreader/IBM Plex |
| Motion | springy + balanced | Playful check pops for a tutorial |
| Nav | none — Home + header Settings + FAB Add | Three-screen product; not bottom tabs / centre hail / floating pill |
| Onboarding | welcome | One hero + Get started; no auth |
| Home skeleton | H1 metric | Day ring + checklist |
| Signature | day ring fill | Check pops → ring fills → streak counts |
| Art | Real morning / wellness photos (sourced) | Onboarding hero + settings about |

## Screens built
| Screen | Skeleton | Job |
|--------|----------|-----|
| Splash | brand beat | Logo + name |
| Onboarding | W1 welcome | Introduce habit check + day ring |
| Home | H1 metric | List habits, toggle done, show streaks + day progress |
| Add habit | F1 form | Name + icon → save to local list |
| Settings | preference list | Profile, reduce motion, about |

## Later
- Persist habits across restarts
- Reminders / notifications
- History chart
- Backend sync (only if asked)
