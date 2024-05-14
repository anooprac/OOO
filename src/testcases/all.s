.arch armv8-a
.global main
.text

main:
    ldur    x0, [x1, #0]    // Load doubleword (64 bits) with unscaled offset
    ldp     x2, x3, [sp], #16   // Load pair of registers
    stur    w4, [x5, #0]    // Store word (32 bits) with unscaled offset
    stp     x6, x7, [sp] // Store pair of registers with pre-index
    movk    x8, #0xFFFF, lsl #16    // Move 16-bit immediate and keep other bits
    movz    x9, #0xFFFF, lsl #32    // Move 16-bit immediate and zero other bits
    adr     x10, label      // Calculate address relative to PC
    adrp    x11, label      // Calculate page address relative to PC
    cinc    x12, x13, eq    // Conditional increment
    cinv    x14, x15, ne    // Conditional invert
    cneg    x16, x17, cs    // Conditional negate
    csel    x18, x19, x20, cc   // Conditional select
    cset    x21, eq         // Conditional set
    csetm   x22, ne         // Conditional set mask
    csinc   x23, x24, x25, hi   // Conditional select increment - exact same as CINC!
    csinv   x26, x27, x28, hs   // Conditional select invert - exact same as CINV!
    //csneg   x29, x30, x31, lo   // Conditional select negate - exact same as CNEG!
    add     x0, x1, #8      // Add
    adds    x3, x4, x2      // Add and set flags
    sub     x6, x7, #8      // Subtract
    subs    x9, x10, x10    // Subtract and set flags
    cmp     x12, x13        // Compare
    mvn     x14, x15        // Bitwise NOT
    orr     x16, x17, x18   // Bitwise OR
    eor     x19, x20, x21   // Bitwise exclusive OR
    and     x22, x23, #7   // Bitwise AND
    ands    x25, x26, x27   // Bitwise AND and set flags
    tst     x28, x29        // Test bits
    //lsl     x30, x31, #4    // Logical shift left
    lsr     x0, x1, #4      // Logical shift right
    sbfm    x2, x3, #4, #11 // Signed bitfield move
    ubfm    x4, x5, #4, #11 // Unsigned bitfield move
    asr     x6, x7, #4 
         // Arithmetic shift right
    b       label           // Branch
label:
    br      x8              // Branch to register
    b.eq    label1           // Branch if equal
label1:
    bl      func            // Branch with link
func:
    blr     x9              // Branch with link to register
    cbnz    x10, label2     // Compare and branch if not zero
label2:
    cbz     x11, label3      // Compare and branch if zero
label3:
    ret                     // Return from subroutine
    nop                     // No operation             


