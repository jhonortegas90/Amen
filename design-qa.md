source visual truth path: /var/folders/gz/dql5qgtx3f91m5cbxcvpr6r40000gp/T/TemporaryItems/NSIRD_screencaptureui_0LR9cO/Screenshot 2026-07-04 at 11.07.04 AM.png
implementation screenshot path: /Users/jhonalejandroortega/Developer/Amen/onboarding-web-screenshot.png
viewport: 390 x 844
state: onboarding screen, signed-out social auth options visible
full-view comparison evidence: /Users/jhonalejandroortega/Developer/Amen/design-qa-comparison.png
focused region comparison evidence: focused visual review was performed on the central glass message card and bottom authentication card within the full-view comparison; separate crops were not needed because the relevant typography, button icons, link styling, and card edges are readable at this viewport.

**Findings**
- No actionable P0/P1/P2 findings remain.

**Required Fidelity Surfaces**
- Fonts and typography: title, description, button labels, and legal links use crisp white/muted-white hierarchy with zero letter spacing. Button text weight and size now visually match the mockup's social login pills.
- Spacing and layout rhythm: header text/star elements are gone, the logo asset is placed as the only top brand mark, the central card is centered above the auth card, and the bottom card spacing matches the mockup's two-button social-login-only layout.
- Colors and visual tokens: flat solid gold borders were replaced by blurred dark/gold glass fills, gradient edge highlights, and soft warm glow. The cards read as polished glass rather than simple transparent panels.
- Image quality and asset fidelity: the Amen logo is loaded from `assets/images/AppLogo.png`, and the Google button uses a PNG asset from Google's identity resource instead of a custom-painted icon. The existing app collage remains live network imagery and is directionally similar, though not the exact set of background photos in the mockup.
- Copy and content: visible copy matches the mockup for the message, Google sign-in, Apple sign-in, Privacy Policy, and Terms of Service. The guest button and dot separator are absent.

**Patches Made Since Previous QA Pass**
- Added bundled image assets to `pubspec.yaml`.
- Replaced the previous flat bordered glass helper with layered blur, tinted fill, gradient edge, and glow rendering.
- Replaced the custom Google painter with `assets/images/google_g_logo.png`.
- Removed unused onboarding header/guest config strings.
- Tuned glass alpha values darker after the first visual capture.

**Follow-up Polish**
- P3: If the background needs to match the mockup beyond the requested UI changes, replace the current live Unsplash collage URLs with exact approved local image assets for the rolling hills, misty forest, praying hands, family, and sunlight tiles.

final result: passed
