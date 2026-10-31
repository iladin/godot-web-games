# Opcode — design

- **Pitch:** Assembly-language puzzles for a tiny machine with one accumulator, two registers and 14 instructions. Every puzzle is scored on cycles and size against par.
- **Built for:** AI players first (it's programming, it's turn-based, and the full state is on screen and in `window.aiGame`). Humans can play by tapping, with no typing needed.
- **Core loop:** read the task and the visible test → write or edit a few lines → step or run → read the failure (the bad line is highlighted, and the tapes show the wrong output) → fix → shave cycles or lines for stars (~1–10 min per puzzle).
- **Machine:** `IN OUT NEG LDA STA SWP ADD SUB JMP JEZ JNZ JGZ JLZ LBL`. ACC, X and Y are clamped to ±999, and literals are −99..99. Labels A–F are free (0 cycles, 0 size). The last line wraps to the first. A run passes the moment the output is complete, and fails on a wrong output, on IN with no input left, or after 4000 cycles. Score = average cycles over 3 tests (test 1 is shown, 2 are hidden) plus size.
- **Controls:**
  - Touch/mouse: tap an instruction, then its operand (X/Y, a number from the keypad, or a label); it's inserted below the cursor line. Tap a line to move the cursor. UP/DOWN/DEL edit; STEP / RUN (animated) / CHECK (instant) / STOP.
  - Keyboard: type `ADD X` and press Enter to insert. Enter on an empty line runs; Shift+Enter steps; Ctrl+Enter checks; Backspace on an empty line deletes; ↑/↓ move the cursor; Esc stops.
  - AI: the `/` command line or `window.aiGame.act(...)` with `open 7`, `program IN | STA X | IN | NEG | ADD X | OUT`, `run`, `step`, `insert`, `delete N`, `replace N I`, `list`, `next`.
- **Win / score:** each puzzle has 3 stars: solved, size ≤ par, cycles ≤ par. Stars are independent, so best size and best cycles can come from different programs. Solving all 16 shows "Machine mastered". There's no game over; the challenge is the pars. `reset progress` wipes the save.
- **Ramp:** 16 puzzles. I/O basics (echo, +5, ×2) → branching (no zeros, abs, sign, max) → loops (countdown, count up, group sums) → loops that juggle three values through `SWP` (÷3, multiply, Fibonacci, GCD). Puzzles unlock three ahead of your solved count.
- **Pars:** the size and cycles of reference programs in `puzzles.gd`. `selftest.gd` proves every reference passes all tests. They're tight but beatable; beating par is the fun.
- **Juice:** an accelerating animated run with the executing line pulsing, a spark on each correct output, red flash and shake on failure, a burst on solve, and stars on tiles.
- **Out of scope:** audio, more registers, a stack, a histogram of other players' scores.
