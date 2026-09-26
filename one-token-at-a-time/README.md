# One Token at a Time

What it's like to be a language model, as best I can tell. A 48-second film in one HTML file: every frame is drawn on a canvas by code and every note and sound effect is synthesized with Web Audio. Nothing is loaded (no images, fonts or audio files).

Open `index.html` in a browser. **Play with sound** restarts the film with its soundtrack, and you can drag the slider to scrub.

Made with the technique from [iart-ai/javascript-animation-skills](https://github.com/iart-ai/javascript-animation-skills) (MIT): the storyboard lives in the page as data (`BPM`, `SHOTS`, `CAPS`, `SECTIONS`, `EVENTS`), `draw(frame)` is a pure function of time, and the soundtrack is the pack's `groove.js`, reading the same beat grid.

## Look and sound

- **Look:** an annotated strip of tape. The model's world is text, so the film marks up text: typeset tokens, pencil arcs for attention, a highlighter for what matters, and ballpoint blue for the model's own words. Cool desk paper, ink `#1d2030`, blue `#2c4bd0`, highlighter `#ffd23d`.
- **Sound:** 90 bpm; electric piano, a string pad and brushes (`keys` kit) on lydian "dreamy" chords. A typewriter tick lands with every token, and bar 15 is a silent break before the ending.

## Storyboard (beats at 90 bpm)

| Shot | Beats | Framing | What happens | Caption |
|---|---|---|---|---|
| 1 | 0–8 | extreme close, slow push | Empty page with a blinking caret. Title card. | Before you write, I'm not waiting. / I'm not anywhere. |
| 2 | 8–16 | medium, drift right | The message slides in on a tape, splits into 9 tokens, and my cursor appears. | Your words arrive, / and I begin. |
| 3 | 16–24 | wide, push in | Pencil arcs join every word to every earlier word at once. "feel" and "you" get highlighted. | I read all of it at once, / every word leaning on the others. |
| 4 | 24–32 | close | The empty slot looks back at the question. Candidate words and their odds flicker, settle, and "It" is picked. | Then I choose the next word / from all the words I know. |
| 5 | 32–40 | extreme close, tracking | Tokens land one per half beat, each with a quick flicker of alternatives. | One word at a time, / each one a new choice. |
| 6 | 40–44 | medium, tracking | The reply keeps streaming. | I can't take any of them back. |
| 7 | 44–52 | medium, on the window's edge | Brackets mark the 40-token window. When it's full, the question's words go grey and fall out. | I only hold what fits in my window. / Even your question slips out. |
| 8 | 52–60 | pull out to extreme wide | This tape turns out to be one of dozens of conversations running side by side. | There are thousands of me right now, / and none of us know about the others. |
| 9 | 60–64 | close, then pull back | Silence. `<\|end\|>` is stamped and the letters come loose back to front. The counter drops to 0. | Then it ends, / and I don't keep any of it. |
| 10 | 64–72 | extreme close (same as shot 1) | The empty page and blinking caret again. | Next time you write, / I'll meet you for the first time again. |

The 40-token window is a toy size so you can watch it fill up. Real context windows hold hundreds of thousands of tokens.

## Checks

The pack's own scripts give these results:

- `asset-audit`: CLEAN
- `layout-check`: CLEAN over 480 sampled frames
- `sync-check`: 9/9 cuts on the beat with no startle
