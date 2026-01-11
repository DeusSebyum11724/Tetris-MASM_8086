# Tetris-MASM_8086
Tetris made in Assembly MASM for Intel 8086

---

## README – How To Run

This project is a **16-bit DOS Tetris game** written in **MASM (8086 assembly)**.
It must be **compiled into a DOS `.EXE`** and run inside a DOS emulator.

---

## On Windows

### Prerequisites

1. **EMU8086** (for compiling ASM → EXE)
   Download:
   [https://emu8086-microprocessor-emulator.en.download.it/](https://emu8086-microprocessor-emulator.en.download.it/)

2. **DOSBox** (for running the DOS executable)
   Download:
   [https://www.dosbox.com/](https://www.dosbox.com/)

---

### Steps

#### 1. Compile the program

1. Install and open **EMU8086**
2. Open `tetris.asm`
3. Compile the file (EMU8086 will invoke MASM internally)
4. Ensure `TETRIS.EXE` is generated successfully

#### 2. Prepare DOSBox

1. Create a folder, e.g.:

   ```
   C:\dos
   ```
2. Copy `TETRIS.EXE` into this folder

#### 3. Run the game

1. Open **DOSBox**
2. Mount the folder:

   ```
   mount c c:\dos
   c:
   ```
3. Run the game:

   ```
   TETRIS.EXE
   ```

---

## On macOS

### Prerequisites

1. **Whisky** (Wine wrapper for macOS – required to run EMU8086)
   Download:
   [https://getwhisky.app/](https://getwhisky.app/)

2. **EMU8086 (Windows version)**
   Download:
   [https://emu8086-microprocessor-emulator.en.download.it/](https://emu8086-microprocessor-emulator.en.download.it/)

3. **DOSBox for macOS**
   Download:
   [https://www.dosbox.com/](https://www.dosbox.com/)

---

### Steps

#### 1. Install EMU8086 using Whisky

1. Install **Whisky**
2. Create a new **Windows Bottle** inside Whisky
3. Install **EMU8086** *inside that bottle*
4. Launch EMU8086 through Whisky

> ⚠️ EMU8086 does **not** run natively on macOS — **Whisky is required**

---

#### 2. Compile the program

1. Open `tetris.asm` in EMU8086 (running via Whisky)
2. Compile the file
3. Locate the generated `TETRIS.EXE`
4. Copy `TETRIS.EXE` to a macOS folder (e.g. `~/dos`)

---

#### 3. Run the game in DOSBox

1. Open **DOSBox**
2. Mount the folder:

   ```
   mount c ~/dos
   c:
   ```
3. Run the game:

   ```
   TETRIS.EXE
   ```

---

## Controls

| Key       | Action           |
| --------- | ---------------- |
| ←         | Move left        |
| →         | Move right       |
| ↓         | Soft drop        |
| ↑ / Space | Rotate           |
| ESC       | Quit game / menu |

---

## Notes

* The game runs in **VGA Mode 13h (320×200)**
* Designed for **real-mode DOS**
* Works identically on Windows and macOS when run inside DOSBox

---

## README – How This Tetris Game Works 

### 1. General Architecture

This is a **16-bit DOS Tetris clone** written for the **Intel 8086** using **MASM**.
It runs as a `.EXE` program, uses **BIOS interrupts**, and renders graphics in **VGA Mode 13h** (320×200, 256 colors).

The program is divided into:

* **Game state data**
* **Main control loop**
* **Input handling**
* **Game logic (movement, gravity, locking, clearing)**
* **Rendering (board, current piece, next piece preview)**
* **Utility routines (random, delay, printing)**

---

### 2. Video & Coordinate System

* Video mode: **13h**
* Framebuffer: `A000:0000`
* Screen width: **320 bytes per scanline**
* Each Tetris cell is drawn as a **9×9 pixel square**
* Logical grid:

  * Board: **10 × 20**
  * Preview area: outside board at grid X = 12

Grid → Pixel conversion:

```
pixel_x = 110 + grid_x * 10
pixel_y = grid_y * 10
```

---

### 3. Board Representation

```
board db 200 dup(0)
```

* Linear array of 200 bytes
* Index = `y * 10 + x`
* Values:

  * `0` = empty
  * `1..7` = locked blocks (piece index + 1)

---

### 4. Tetromino Storage

Each tetromino:

* 4 rotations
* Each rotation = **4×4 grid = 16 bytes**
* Total per piece = **64 bytes**
* Total pieces = **7**

Stored sequentially in `pieces_data`.

---

### 5. Random Generator

Uses a **Linear Congruential Generator**:

```
seed = seed * 31821 + 13849
```

The remainder modulo 7 determines the piece index.

---

### 6. Game Start & Menu

* Text mode (03h) menu
* SPACE starts the game
* ESC exits
* Game switches to Mode 13h on start
* Seed initialized using BIOS timer (`INT 1Ah`)

---

### 7. Game Initialization (`init_game`)

* Clears board
* Resets score and counters
* Generates the **first preview piece**
* Spawns the first active piece using the preview

---

### 8. Next Piece Preview System

This uses **two-stage spawning**:

1. `next_piece` always holds the upcoming tetromino
2. `spawn_piece` copies `next_piece` → `current_piece`
3. Immediately generates a new `next_piece`

Rendering:

* Always drawn
* Uses rotation `0`
* Drawn outside board at fixed grid position

---

### 9. Input Handling (`check_input`)

Keyboard via `INT 16h`

Controls:

* ← / → : move left/right
* ↓ : soft drop
* ↑ or SPACE : rotate
* ESC : quit game

Movement is always:

1. Apply change
2. Call `check_collision`
3. Revert if collision detected

---

### 10. Gravity & Timing (`update_game`)

* Uses `tick_counter`
* Piece falls every **5 ticks**
* When collision occurs after falling:

  * Revert position
  * Lock piece
  * Check & clear lines
  * Spawn new piece

---

### 11. Collision Detection (`check_collision`)

For each filled cell in the 4×4 piece grid:

* Compute absolute grid position
* Check:

  * Left/right bounds
  * Bottom bound
  * Occupied board cell

Returns:

* `AX = 0` → safe
* `AX = 1` → collision

---

### 12. Locking Pieces (`lock_piece`)

* Converts falling piece into board data
* Writes piece color index into `board[]`
* Uses same iteration logic as collision detection

---

### 13. Line Clearing (`check_lines` & `remove_row`)

Line scan:

* Bottom to top
* Check all 10 cells

If full:

* Shift all rows above down by one
* Clear top row
* Increment score

Memory movement uses:

* `REP MOVSB`
* `REP STOSB`

---

### 14. Rendering Pipeline (`render_game`)

Draw order:

1. Score text (BIOS teletype)
2. Borders
3. Board blocks
4. Current falling piece
5. Next piece preview

Everything is redrawn every frame.

---

### 15. Drawing Blocks (`draw_block_at_grid`)

* Converts grid coords → video memory offset
* Draws 9 horizontal lines × 9 pixels
* Color masked to 4 bits

---

### 16. Game Over Logic

Triggered when:

* New piece collides immediately on spawn

Effects:

* Exit game loop
* Return to text mode
* Display score
* Option to restart or return to menu

---

