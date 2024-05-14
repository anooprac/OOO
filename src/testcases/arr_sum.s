.arch armv8-a
.global main
.text

main:                                   // @main
        sub     sp, sp, #64
        stur     xzr, [sp, #60]
        mov     x8, #1                          // =0x1
        stur     x8, [sp, #24]
        mov     x8, #2                          // =0x2
        stur     x8, [sp, #32]
        mov     x8, #3                          // =0x3
        stur     x8, [sp, #40]
        mov     x8, #4                          // =0x4
        stur     x8, [sp, #48]
        ldur     x8, [sp, #48]
        stur     x8, [sp, #16]
        ldur     x8, [sp, #24]
        stur     x8, [sp, #48]
        ldur     x8, [sp, #16]
        stur     x8, [sp, #24]
        ldur     x8, [sp, #40]
        stur     x8, [sp, #16]
        ldur     x8, [sp, #32]
        stur     x8, [sp, #40]
        ldur     x8, [sp, #16]
        stur     x8, [sp, #32]
        stur     xzr, [sp, #8]
        stur     xzr, [sp]
        b       .LBB0_1
.LBB0_1:                                // =>This Inner Loop Header: Depth=1
        ldur     x8, [sp]
        mov     x10, #4
        subs    x8, x8, x10
        b.ge    .LBB0_4                 // loop cond
        b       .LBB0_2
.LBB0_2:                                //   in Loop: Header=BB0_1 Depth=1
        ldur     x9, [sp]               // i
        add     x8, sp, #24             // arr base addr
        lsl     x10, x9, #3             // Loading arr[i]
        adds    x10, x10, x8
        ldur    x9, [x10]

        ldur     x8, [sp, #8]
        adds     x8, x8, x9             // sum += arr[i];
        stur     x8, [sp, #8]
        b       .LBB0_3
.LBB0_3:                                //   in Loop: Header=BB0_1 Depth=1
        ldur     x8, [sp]
        add     x8, x8, #1              // i++
        stur     x8, [sp]
        b       .LBB0_1
.LBB0_4:
        ldur     x8, [sp, #8]
        mov     x0, x8
        add     sp, sp, #64
        ret
        