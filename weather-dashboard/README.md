# Skyglass Weather

A single-file weather dashboard: current conditions, daylight, six condition tiles,
a 24-hour temperature and rain chart, and a 7-day forecast.

## Run it

Open `index.html` in a browser. There is no build step and no API key.

Or serve the folder locally:

```bash
npx serve weather-dashboard
```

## Data

- Forecasts come from the free [Open-Meteo](https://open-meteo.com/) forecast API (CC BY 4.0).
- City search uses the Open-Meteo geocoding API. "My location" uses the browser's geolocation.
- If the service can't be reached, the page shows clearly labelled example data for London
  instead of an empty screen.
- The last city and the unit choice (°C / °F) are remembered in `localStorage`.

## Design

The visual direction was generated with the **UI/UX Pro Max** skill
(`.claude/skills/ui-ux-pro-max`, from
[nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)):

```bash
python3 .claude/skills/ui-ux-pro-max/scripts/search.py \
  "weather forecast dashboard clean minimal" --design-system \
  -p "Weather Dashboard" --density 6 --variance 4 --motion 3
```

| Decision | From the skill | Applied as |
|---|---|---|
| Style | Glassmorphism (Weather App: "Glassmorphism + Aurora UI") | Frosted cards over a sky gradient |
| Color | Sky blue `#0284C7`, sun amber `#F59E0B`, background `#F0F9FF` | Tokens in `:root`, with a matching dark theme |
| Palette focus | "Atmospheric gradients + temp scale" | The sky changes with the current conditions; 7-day bars shade from cool to warm |
| Typography | Fira Sans + Fira Code | Fira Sans for text and figures, Fira Code for labels and axes |
| Charts | Line/area chart, table fallback, keyboard access | 24-hour area chart and rain bars, arrow-key readout, hourly table |
| UX rules | Contrast 4.5:1, 44px targets, visible labels, loading feedback, reduced motion | Applied throughout |

Two adjustments to the generated system:
- Buttons use `#0369A1` with white text, because white on `#0284C7` is below 4.5:1 contrast.
- The generated "Hero-Centric" landing-page pattern was skipped. It doesn't fit a dashboard.
