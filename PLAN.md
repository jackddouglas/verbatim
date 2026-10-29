# Verbatim

Build a native macOS SwiftUI app to extract complete locally cached Apple Podcasts transcripts.

- Verify Apple's current local TTML format and metadata mapping against this Mac.
- Implement and test parsing, including nested word spans, entities, and malformed files.
- Add read-only cache discovery and episode metadata, preserving unmatched files.
- Add a searchable episode list, transcript reader, copy, and text export.
- Build a launchable app bundle and verify real cache extraction and UI launch.

Scope: no private download API, audio transcription, or claim that an uncached episode is available. Export all paragraphs present in the cached file; cache completeness relative to the audio cannot be guaranteed. Apple's private cache layout may change.

## Completed verification (2026-10-29)

- Six parser/discovery tests pass on Swift 6.4 / macOS 27 SDK.
- Release app built and ad-hoc signature verified with `codesign --verify --strict`.
- Real cache: five files, 635 paragraphs, 34,549 words; each file's counts match an independent Python XML parse.
- Live app: initial cache access denied by macOS; selecting the Podcasts container in Choose Folder successfully loaded all five episodes with titles.
- Live Copy All changes to Copied. Live Export saved `/private/tmp/verbatim-export-check.txt`; all 104 paragraphs and 8,325 words match independently extracted source text exactly.
- Window visually inspected. App left open with the real library loaded.
- Not verified: older macOS versions, distribution/notarization, or cache completeness against episode audio. Selected custom folders are session-only; choose again after relaunch if needed.

## macOS 27 native interface refinement

Use Apple's current HIG and Liquid Glass adoption guidance. Target macOS 27; use standard sidebar, toolbar, search, menus, semantic type, and system glass button style. Keep glass on controls/navigation, retain the unobstructed reading surface, and expose toolbar actions in the menu bar. Verify the built app and record remaining accessibility/display checks.

### Refinement verification

- Release built with Xcode 27.1; binary reports minimum macOS 27.0 and SDK 27.0. Strict signature verification passes.
- Six tests pass after the interface changes.
- Relaunched the actual app on macOS 27.0.1. Visually inspected native glass toolbar groups, sidebar search, corrected sidebar minimum width, and semantic reading hierarchy.
- Live checked Copy Transcript via Shift-Command-C, options menu, timestamps, Export via Shift-Command-E, sidebar search, no-results state, and View menu commands.
- Timestamped UI export matches independent XML extraction exactly across 104 paragraphs.
- Not verified: dark appearance, Reduce Transparency, Increase Contrast, Reduce Motion, VoiceOver navigation, and narrow-window toolbar overflow. Native controls use system adaptation; this is not a claim of exhaustive HIG compliance.

## Search placement correction

Move episode search to the standard trailing toolbar using `.searchable(placement: .toolbar)` on the split view. Preserve native styling and existing filtering. Rebuild and verify the running app.

Verified: release rebuild succeeded; relaunched app shows search at the upper-right end of the toolbar. Typing a title filters the episode list; clearing search restores it. Visually confirmed native toolbar placement.

## Layered application icon

Recreate the supplied purple podcast/transcript concept as vector layers in Icon Composer, using generation 27 effects. Preserve editable source and compile the .icon with actool into the app bundle. Verify appearances and bundle integration.

Completed: five vector layers assembled in four Icon Composer groups; generation 27 default, dark, and monochrome previews inspected. `actool` compiled the icon into the release bundle; strict code-signature verification passed. Editable document retained in Resources/Verbatim.icon.

## Podcasts baseline study

User requested matching the original Podcasts icon before adding a Verbatim variation. Keep the prior app icon intact. Reconstructed the two filled discs and tapered figure in Resources/Podcasts-Study.icon and verified it opens in Icon Composer with generation 27 effects. Compiled successfully with actool after retrying outside the sandbox. Native exported preview is build/Podcasts-study-1024.png. Remaining discrepancy: exact original gradient and material parameters; investigate extracting the installed app's authored layers for a more faithful baseline.

Superseded the approximation with Resources/Podcasts-Original.icon, recovered from the installed Podcasts Assets.car. Original three SVG paths, four groups, exact named gradients, blending, opacity, shadows, translucency, blur, refraction and appearance-specific values are retained. Native generation 27 default and dark previews checked. Prior Verbatim icon remains intact; the baseline is for the next design iteration. Recovery API/schema reference: https://github.com/kylebshr/decant; a small local read-only CoreUI extractor was used because source download approval timed out.

Verification: original-default compiled preview vs installed AppIcon.icns at 256x256, decoded into sRGB: mean absolute RGBA channel difference 0.001119 (0.285/255), 5,155 pixels differ by more than 1/255. This is not pixel identity. Final appearance serialization checked live in Icon Composer, including dark. A final recompilation attempt timed out in automatic approval review; the preceding compilation succeeded. No app integration changes made in this baseline pass.

## Transcript variation on approved baseline

Add a restrained folded transcript page in the lower-right, using the recovered Podcasts geometry and palette. Preserve Podcasts-Original.icon and archive the first-pass icon. Use four native material groups: page, voice, inner disc, outer disc. Verify default/dark/mono previews, small-size legibility, asset compilation and signed app build.

Completed: added the transcript variation to Resources/Verbatim.icon and rebuilt build/Verbatim.app. actool compilation and strict code-signature verification passed. Inspected the compiled 256px preview and the current document's dark and monochrome appearances in Icon Composer after closing its stale first-pass document. Original baseline and first-pass archive retained.

## Transcript page polish

Refine the page with a slightly broader silhouette, smaller corner radii, a more compact fold, thinner evenly spaced lines, and softer shadow/refraction. Preserve the prior version in Resources/Archive/Verbatim-transcript-v1.icon. Verify the compiled icon and signed bundle.

Verified: release build and icon compilation succeeded; strict signature verification passed. Reopened the saved file in Icon Composer and inspected the refined default appearance. Exported the compiled app-icon preview to build/Verbatim-icon-refined.png.

## Pen direction

Replace the central Podcasts figure with a vertical fountain-pen nib; retain the original discs and native materials. Remove the transcript page for this direction. Preserve the refined page icon in Resources/Archive/Verbatim-transcript-refined.icon. Verify compiled appearance and rebuild the app.

Verified: final pen variation compiled successfully, compiled 256px icon visually inspected, app rebuilt and strict signature verification passed. Preview: build/Verbatim-pen-preview.png. Dark/monochrome variants inherit the baseline materials but were not visually rechecked in this pass.

## Sidebar footer removal

Removed the transcript-count footer, its divider, and footer spinner from the sidebar. Release app rebuilt and strict signature verification passed. Running-window appearance not rechecked in this pass.

Rotated the pen nib 180 degrees around its own center, preserving its position over the discs. Release build and strict signature verification passed; compiled icon preview checked.

## Nib tip correction

Replaced the overlapping even-odd cutout with a single open contour, eliminating the stray cap above the nib tip. Widened the slit from 18 to 24 points and extended the base to y=944 (98 points below the outer disc).

Verified: final asset compilation and release build passed; strict signature verification passed. Compiled 256px preview inspected: open tip has no connecting cap, and the base extends visibly below the outer disc. Preview: build/Verbatim-pen-open-tip.png.

## Empty-state cleanup

Replace the three competing landing actions with one compact native Open Apple Podcasts button and concise instructions. Folder selection and Refresh remain in the toolbar. Simplify the sidebar placeholder and distinguish initial loading, an empty library, and a loaded library without a selection. Verify the release build and current empty-state layout.

Verified: release build and strict code-signature check passed. Relaunched the app and visually inspected the empty-library layout: short sidebar label, concise centered guidance, and one compact primary action. Not verified: populated-library selection state, localization, RTL, accessibility text scaling, and minimum-width resizing in this pass.

## Dock icon diagnosis

Confirmed the running process uses build/Verbatim.app with regular activation policy. NSRunningApplication.icon resolves the current purple nib; NSWorkspace bundle-icon TIFF export appeared blank. Targeted LaunchServices registration did not resolve the user's Dock symptom. Refreshed the bundle timestamp, restarted Dock without changing preferences, and relaunched Verbatim. Dock accessibility inspection repeatedly timed out, so its final visible icon remains unverified.

## Shorter nib

User confirmed the Dock icon appeared after the Dock restart. Shortened the nib base from y=944 to y=922, matching the original Podcasts figure's bottom edge (76 points below the outer disc). Updated both SVG sources. Release build, icon compilation and strict signature verification passed; compiled preview inspected at build/Verbatim-pen-shorter.png. Refreshed Dock and reopened the app; final Dock appearance not directly inspected.
