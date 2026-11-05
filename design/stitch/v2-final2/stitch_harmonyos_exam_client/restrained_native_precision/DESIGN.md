---
name: Restrained Native Precision
colors:
  surface: '#f8f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f8f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#434656'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#737687'
  outline-variant: '#c3c5d8'
  surface-tint: '#0050e3'
  primary: '#0044c4'
  on-primary: '#ffffff'
  primary-container: '#0a59f7'
  on-primary-container: '#e4e7ff'
  inverse-primary: '#b5c4ff'
  secondary: '#525f70'
  on-secondary: '#ffffff'
  secondary-container: '#d3e1f5'
  on-secondary-container: '#576475'
  tertiary: '#8c3500'
  on-tertiary: '#ffffff'
  tertiary-container: '#b34600'
  on-tertiary-container: '#ffe3d8'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b5c4ff'
  on-primary-fixed: '#00164e'
  on-primary-fixed-variant: '#003baf'
  secondary-fixed: '#d6e4f8'
  secondary-fixed-dim: '#bac8db'
  on-secondary-fixed: '#0f1c2b'
  on-secondary-fixed-variant: '#3b4858'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb596'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7c2e00'
  background: '#f8f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  display-score:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-score-mobile:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  caption-unit:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.25rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-tablet: 1.5rem
  margin-desktop: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
  space-2xl: 2rem
---

## Brand & Style

This design system embodies the official, disciplined aesthetic of native HarmonyOS system-level utility applications. It is strictly utilitarian, calm, and architectural—crafted specifically for high-stakes productivity and standardized certification environments where sensory friction must be eliminated.

### Brand Personality & Mood
- **Disciplined & Objective:** Avoids gratuitous delight, visual noise, promotional banners, or marketing gradients. Every pixel serves legibility and spatial order.
- **System-Native Trust:** Employs precise typography, crisp card geometry, and high-contrast typographic hierarchies that convey absolute authority and correctness.
- **Calm Focus:** Balances generous whitespace with strict containment, mitigating cognitive fatigue during long exam and verification sessions.

### Visual Style
- **Corporate / Native Modernism:** Derived from the HarmonyOS human factors design philosophy. It utilizes layered neutral planes, discrete white containers against a mist-neutral backdrop, hairline boundaries, and purposeful electric blue primary accents.
- **Zero Decorative Bloat:** Strictly no diffuse background mesh gradients, no glassmorphic blurs, and no skeuomorphic lighting. Visual interest is produced solely via typographic scale, crisp information grouping, and micro-metric status tags.

## Colors

The palette is engineered around the standard HarmonyOS color hierarchy: a cold-neutral system foundation, pure white functional surfaces, an authoritative electric blue interactive accent, and instant-read semantic signaling.

### Color Tokens & Roles
- **Canvas & Surfaces:**
  - `surface-canvas`: `#F1F3F5` — Default window and system background tone.
  - `surface-subtle`: `#F5F7F9` — Secondary grouped-list background and inset regions.
  - `surface-card`: `#FFFFFF` — Primary content surface with maximum contrast.
  - `surface-overlay`: `rgba(24, 36, 49, 0.40)` — Dimmer backdrop for modal verification.
- **Primary Interactive:**
  - `primary`: `#0A59F7` — HarmonyOS signature system electric blue. Reserved strictly for key action buttons, selected states, and active pagination.
  - `primary-subtle`: `rgba(10, 89, 247, 0.08)` — Tonal selection background for active choice states and chip tags.
- **Text & Content Hierarchy:**
  - `text-primary`: `#182431` — High-contrast deep slate for titles, scores, and primary numbers.
  - `text-secondary`: `#525F70` — Balanced neutral for standard body, questions, and explanations.
  - `text-tertiary`: `#8A95A5` — Subordinate neutral for metadata, footnotes, and unit labels.
  - `text-disabled`: `#BAC2CE` — Deactivated commands and placeholders.
- **System Semantic Indicators:**
  - `success`: `#00B578` (Success/Passed indicators, valid options).
  - `success-surface`: `rgba(0, 181, 120, 0.08)`.
  - `warning`: `#FA6400` (Flagged questions, pending verification, alerts).
  - `warning-surface`: `rgba(250, 100, 0, 0.08)`.
  - `error`: `#E84026` (Incorrect selection, hard system errors, timer expiration).
  - `error-surface`: `rgba(232, 64, 38, 0.08)`.
- **Borders & Dividers:**
  - `border-hairline`: `rgba(0, 0, 0, 0.04)` — Structural separation for cards and grouped lists.
  - `border-focus`: `rgba(10, 89, 247, 0.40)` — Precise input and radio focus boundaries.

## Typography

The type system prioritizes high-contrast legibility, rigorous proportional rhythm, and metric pairings common in system certification environments. In native implementations, this maps directly to `HarmonyOS Sans`, falling back to system-ui.

### Application Rules
- **Numeric Hierarchy:** When rendering scores, timers, or completion percentages, large tabular numerals (`display-score` or `headline-lg`) are paired directly with small uppercase or subdued units (`caption-unit`) in `#8A95A5`, baseline-aligned.
- **Exam Content Contrast:** Question titles and options are kept dense and structural with `#182431`, utilizing a generous line height (`26px` on `16px` font) to facilitate rapid scanning under time constraints.
- **Metadata and Badging:** Status pills, chapter identifiers, and time stamps employ `label-sm` or `caption-unit` to keep visual prominence focused strictly on task execution.

## Layout & Spacing

Layout adheres to an 8-point spatial cadence, adjusting dynamically across mobile, folding screen, and tablet/desktop viewports typical of HarmonyOS multi-device continuity.

### Grid & Breakpoints
- **Mobile (< 600px):** Single-column vertical stream. Margin: `16px` (`margin`), Gutters: `16px`. Content cards stretch full width to maximize readable surface.
- **Foldable & Tablet (600px - 1024px):** Split-view master-detail or dual-column layout. Margin: `24px` (`margin-tablet`), Gutters: `20px` (`gutter-tablet`). Maximum content width capped at `960px` for centered exam forms.
- **Desktop / Wide Display (> 1024px):** 12-column structured grid centered with a max-width of `1200px`. Margin: `40px` (`margin-desktop`), Gutters: `24px` (`gutter-desktop`).

### Density & Rhythms
- Card internal padding is fixed at `16px` (`space-lg`) on mobile, expanding to `24px` (`space-xl`) on larger screens.
- Spacing between adjacent modular cards is held at `12px` (`space-md`) or `16px` (`space-lg`) to preserve distinct container grouping without fragmenting page unity.

## Elevation & Depth

Depth in this system is low-profile and disciplined, avoiding dramatic z-axis separation. It favors structural plane grouping over heavy physical projection.

### Elevation Levels
- **Level 0 (Canvas Base):** Flat `#F1F3F5`. No shadow, no outline.
- **Level 1 (Standard Card & Container):** `#FFFFFF` resting plane. Enhanced with a hairline border `rgba(0, 0, 0, 0.04)` combined with an ambient micro-shadow: `0 1px 2px 0 rgba(0, 0, 0, 0.03)`. This defines discrete boundary perimeters without visual heft.
- **Level 2 (Hovered Card / Active Option):** `#FFFFFF` with primary border accent `rgba(10, 89, 247, 0.35)` and micro-shadow: `0 4px 12px -2px rgba(10, 89, 247, 0.06), 0 2px 4px 0 rgba(0, 0, 0, 0.02)`.
- **Level 3 (Sticky Nav & Bottom Actions):** `#FFFFFF` backdrop with top-edge hairline border `rgba(0, 0, 0, 0.06)` and soft downward ambient bleed: `0 -4px 16px 0 rgba(0, 0, 0, 0.03)`.
- **Level 4 (System Dialog & Inspection Sheets):** Elevated centered container with `0 16px 32px -4px rgba(24, 36, 49, 0.08), 0 4px 8px 0 rgba(0, 0, 0, 0.02)`.

## Shapes

The geometric signature uses unified, soft curvature inspired by HarmonyOS squircle design standards.

### Corner Radius Mapping
- **Cards & Primary Modules:** `16px` (`rounded-lg` under `roundedness: 2` scale) on mobile; up to `20px` (`rounded-xl`) on expanded container views.
- **Buttons & Action Triggers:** Standard buttons use `8px` (`rounded-md`) for structured stability, while quick tags and indicator chips use full circular/pill curves.
- **Checkboxes & Selection Nodes:** `6px` radius for multi-select checkboxes; complete circular radius for single-select radios.
- **Inputs & Fields:** `10px` to `12px` roundedness to provide visual containment distinct from the surrounding card boundaries.

## Components

### Buttons
- **Primary:** Solid `#0A59F7` background, `#FFFFFF` text, `font-weight: 500`. No gradient. Micro active press state compresses scale slightly to `0.98` with background `#084ECC`.
- **Secondary / Subdued:** Background `rgba(10, 89, 247, 0.08)`, text `#0A59F7`. Used for secondary workflows like "Previous Question" or "Bookmark".
- **Ghost:** Transparent background, `#525F70` text, highlighting to `#F5F7F9` on hover/press.

### Cards
- Pure white background (`#FFFFFF`), `16px` corner radius, `16px` to `20px` internal padding.
- Encased in a `1px` border using `rgba(0, 0, 0, 0.04)`.
- Divided internally with subtle inset horizontal lines (`rgba(0, 0, 0, 0.04)`) rather than full gaps when grouping sub-items.

### Chips & Status Tags
- Height: `24px` or `28px` with compact horizontal padding (`8px` to `10px`).
- Border radius: Fully pill-shaped.
- Construction: Hairline border paired with matching tint background (e.g., Success tag: `rgba(0, 181, 120, 0.08)` fill, `#00B578` text, `border: 1px solid rgba(0, 181, 120, 0.20)`).

### Option Selectors (Single & Multi-Select)
- Unselected: White container with `rgba(0, 0, 0, 0.05)` border, text `#525F70`.
- Selected: Border changes to `#0A59F7`, surface changes to `rgba(10, 89, 247, 0.04)`, title shifts to high-contrast `#182431`.
- Verified Correct/Incorrect State: Swaps accent color immediately to `#00B578` (Success) or `#E84026` (Error) with matching soft tint fill.

### Metric Header / Stat Panels
- Large tabular figures (`display-score-mobile` or `headline-lg`) displayed in `#182431`.
- Paired with `#8A95A5` label positioned above or below the numeral, strictly avoiding decorative icons or badge clutter.

### Input Fields
- Surface: `#F5F7F9` (resting) shifting to `#FFFFFF` upon active focus.
- Hairline border of `rgba(0, 0, 0, 0.08)` transitioning to a crisp `1.5px` border of `#0A59F7` on focus.
- Placeholder text: `#BAC2CE`.