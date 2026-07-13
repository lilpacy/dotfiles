# Theme Catalog

Use this file for catalog theme rotation and diversification. It is the local
source of truth for each theme's three axes. Optional files under
`references/themes/` add signature moves for selected themes; they do not replace
this table.

| Theme | Genre cluster | Paper band | Display style | Accent hue |
| --- | --- | --- | --- | --- |
| Specimen | editorial | light | high-contrast-serif | warm |
| Atelier | editorial | light | high-contrast-serif | warm |
| Brutal | editorial | light | display-heavy | neutral |
| Newsprint | editorial | light | roman-serif | warm |
| Studio | editorial | light | high-contrast-serif | chromatic-other |
| Manifesto | editorial | mid | geometric-sans | neutral |
| Terminal | atmospheric | dark | mono | chromatic-other |
| Midnight | atmospheric | dark | high-contrast-serif | cool |
| Almanac | editorial | light | roman-serif | warm |
| Garden | editorial | light | roman-serif | chromatic-other |
| Riso | editorial | light | risograph-bold | warm |
| Sport | editorial | light | display-condensed | warm |
| Bloom | atmospheric | light | roman-serif | warm |
| Coral | modern-minimal | light | geometric-sans | warm |
| Cobalt | modern-minimal | light | grotesk-sans | cool |
| Aurora | atmospheric | dark | geometric-sans | cool |
| Editorial | editorial | light | roman-serif | neutral |
| Carnival | editorial | light | display-heavy | per-drop |
| Lumen | atmospheric | dark-or-light | classical-serif-lowercase | warm-or-cool |
| Hum | playful | light | rounded-sans | multi |

## How To Use

- Compare against the newest `.hallmark/log.json` entry or CSS stamp.
- Pick a theme that differs on at least one axis from the previous theme.
- If an optional theme file declares a drop, record both theme and drop in the
  log, e.g. `Carnival / Citrus Riot` or `Lumen / Day Foundry`.
- When a theme has `per-drop`, `warm-or-cool`, or `dark-or-light`, use the chosen
  drop's values from that theme file for the final comparison.
- If a theme has no optional file, construct tokens from `color.md` and
  `typography.md` using the axes above.
