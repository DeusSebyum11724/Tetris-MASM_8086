Below is a **separate, engineering-focused README** intended for **low-level programmers, reverse engineers, and systems students**.
It complements the functional README by explaining **design decisions, constraints, trade-offs, memory models, CPU behavior, and DOS/VGA engineering details**.

---

# ENGINEERING README

## TETRIS.EXE — 8086 / DOS / VGA Mode 13h

---

## 1. Target Environment & Constraints

### CPU

* **Intel 8086 / 8088 compatible**
* 16-bit real mode
* No protected mode, no paging, no cache assumptions

### Operating System

* **MS-DOS**
* `.EXE` format (small memory model)
* BIOS and DOS interrupts available

### Memory Model

```asm
.model small
```

* One code segment
* One data segment
* DS explicitly initialized
* ES used explicitly for video memory and block moves

### Engineering Constraint Summary

| Constraint          | Impact                                 |
| ------------------- | -------------------------------------- |
| 64 KB segment limit | Board + assets must be compact         |
| No hardware sprites | All rendering done in software         |
| No timer interrupts | Game timing done via BIOS tick polling |
| No stack protection | Careful push/pop discipline required   |

---

## 2. Video System Engineering

### VGA Mode 13h

* Resolution: **320×200**
* Color depth: **8-bit indexed (256 colors)**
* Linear framebuffer at segment `A000h`

This mode was chosen because:

* Linear memory layout (no planar access)
* Simple addressing: `offset = y * 320 + x`
* Fast enough for full redraw each frame on 8086-class CPUs

### Framebuffer Access Pattern

```asm
mov ax,0A000h
mov es,ax
stosb
```

* ES explicitly set before writing
* No reliance on DS for video writes
* Prevents accidental memory corruption

---

## 3. Grid → Pixel Mapping Design

### Logical Grid

* Board: **10 × 20**
* Cell size: **10×10 pixels (9 drawn, 1 gap implicit)**

### Why 9×9 blocks?

* Avoids overlap artifacts
* Leaves natural grid separation
* Slight performance gain vs 10×10

### Coordinate Translation

```text
pixel_x = 110 + grid_x * 10
pixel_y = grid_y * 10
```

* Board horizontally centered
* Preview rendered outside board bounds
* No clipping logic required

---

## 4. Data Representation Engineering

### Board Storage

```asm
board db 200 dup(0)
```

* Flat linear array
* Index = `y * 10 + x`
* Cache-friendly sequential access
* Avoids 2D indexing overhead

### Cell Encoding

| Value | Meaning                |
| ----- | ---------------------- |
| 0     | Empty                  |
| 1–7   | Locked tetromino color |

This allows:

* Direct color mapping
* No lookup tables during rendering

---

## 5. Tetromino Encoding Strategy

### Storage Layout

```
[ Piece ][ Rotation ][ 4×4 grid ]
```

* Each rotation = 16 bytes
* Each piece = 64 bytes
* Offset math uses bit shifts only

### Why 4×4?

* Standard Tetris representation
* Simplifies rotation logic
* Avoids per-piece bounding boxes

### Offset Computation

```asm
piece_offset = piece * 64 + rotation * 16
```

Implemented via:

* `SHL` (no MUL needed)
* Faster on 8086

---

## 6. Collision Detection Engineering

### Core Principle

Collision is **predictive**, not reactive.

All moves:

1. Apply change
2. Check collision
3. Revert if invalid

### Collision Checks

For each filled cell in 4×4 grid:

* X ≥ 10 → collision
* Y ≥ 20 → collision
* board[y*10 + x] ≠ 0 → collision

### Why This Works Well

* Single unified collision routine
* No special cases for rotation or movement
* Works for preview, falling, and spawning logic

---

## 7. Game Timing & Synchronization

### No Hardware Timer Used

Instead:

* BIOS tick counter at `0040:006C`
* ~18.2 ticks/second

### Delay Loop

```asm
wait until BIOS tick increments
```

Advantages:

* Portable across DOS machines
* No IRQ hooking
* Stable timing

Trade-off:

* Not frame-perfect
* Speed depends on tick granularity

---

## 8. Random Number Generation

### LCG Design

```text
seed = seed * 31821 + 13849
```

* Fits in 16-bit arithmetic
* Deterministic
* Fast (single MUL)

### Why Not BIOS RNG?

* BIOS has no standard RNG
* Determinism helps debugging

---

## 9. NEXT PIECE PREVIEW ENGINEERING

### Design Goal

Preview must:

* Always be visible
* Never affect collision logic
* Share rendering pipeline

### Implementation Strategy

* Preview uses same `draw_block_at_grid`
* Rendered at grid X > 9
* Uses rotation 0 only

### Data Flow

```
next_piece → current_piece
generate new next_piece immediately
```

This guarantees:

* Preview always valid
* No race conditions

---

## 10. Rendering Architecture

### Full Redraw Strategy

Every frame:

* Clear old visuals implicitly
* Redraw entire scene

Why?

* Simpler than dirty rectangles
* CPU fast enough for small resolution
* Avoids flicker and state bugs

### Draw Order Matters

1. UI text
2. Borders
3. Board
4. Active piece
5. Preview

Ensures:

* Active piece always visible
* Preview never overwritten

---

## 11. Memory Safety & Segment Discipline

### Segment Rules Enforced

* DS → data
* ES → video or copy destination
* ES always explicitly set

### Why This Matters

* `REP MOVSB` and `STOSB` write to ES
* Forgetting ES causes silent corruption
* remove_row explicitly sets ES = DS

---

## 12. Stack & Register Discipline

### Calling Convention (Implicit)

* Caller-saved registers protected manually
* Each PROC pushes/pops what it uses

### Why No Standard Convention?

* DOS/MASM has no enforced ABI
* Manual discipline minimizes overhead
* Critical on small stacks

---

## 13. Performance Considerations

### Optimizations Used

* Bit shifts instead of multiplications
* Linear memory access
* Minimal branching inside loops
* Reuse of procedures for preview & board

### Acceptable Trade-offs

* Full redraw instead of partial
* BIOS timing instead of PIT programming

---

## 14. Failure Modes & Stability

### Game Over Condition

* Collision on spawn
* No undefined states

### Input Safety

* Polling prevents input buffer overflow
* ESC handled universally

### Determinism

* Same seed → same game
* No race conditions

---