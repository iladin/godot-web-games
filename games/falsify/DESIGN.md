# Falsify — design

- **Pitch:** A hidden rule decides which number triples "fit"; run experiments to cross out suspect rules, and name the real one before your lab runs out of funding.
- **Built for:** AI players first (turn-based, full information, text commands), humans welcome. Teaches falsification and information theory: Wason's 2-4-6 task (1960), and why a test that can't prove you wrong is wasted.
- **Core loop:** look at the surviving suspects → design a triple that splits them as evenly as possible → read FITS/NO → watch suspects get struck → repeat or gamble on a name (~10–30 s).
- **Controls:**
  - Touch/mouse: tap the keypad and then TEST; tap a suspect and then NAME IT.
  - Keyboard: type `3 6 9` and press Enter to test; press a letter and then Enter to name; ↑/↓ nudge a number; ←/→ move between numbers.
  - AI: press `/` to open the command line (`test 3 6 9`, `name B`, `next`, `start`, `help`), or use `window.aiGame.observe()` / `window.aiGame.act(cmd)` in the browser.
- **Fail / win:** each test costs 1 funding and each wrong name costs 2. Funding below 0 ends the game ("Defunded"). Naming the rule in all 10 rounds wins ("Tenure granted").
- **Score:** per round `max(10, 100 + 30·(par − tests) − 40·wrong)`; at the end, leftover funding is worth 10 points each. Par is the true minimax number of tests needed to be certain, computed by DP over the suspects' truth tables.
- **Economy:** solving a round pays back `par + 1` funding if you were on par with no wrong guesses, otherwise `par`. Playing on par nets +1 per round, while one wasted test per round slowly bankrupts you.
- **Ramp:** the number of suspects per round goes 4, 4, 5, 6, 6, 7, 8, 8, 9, 10. The share of compound rules (`X AND Y`, `X OR Y`) rises from 0% to 70%. Rules are drawn from a pool of 38 simple predicates.
- **Juice:** strike-through animation for eliminated suspects, a red flash and screen shake on a wrong name, particle burst and floating points on a correct one, a verdict flash on each test, floating −1 funding, and the bits gained shown for every test.
- **Out of scope:** audio, free-form rule entry (naming is multiple choice), hint button.
