.arch armv8-a
.global main
.text
main:                                   // @main
        sub     sp, sp, #16             // =16
        movz    x8, #48879
        movk    x8, #65261, lsl #16
        movk    x8, #57005, lsl #32
        movk    x8, #64206, lsl #48

        movz    x9, #0x5555             // 0x5555555555555555
        movk    x9, #0x5555, lsl #16
        movk    x9, #0x5555, lsl #32
        movk    x9, #0x5555, lsl #48

        movz    x10, #0x3333             // 0x3333333333333333
        movk    x10, #0x3333, lsl #16
        movk    x10, #0x3333, lsl #32
        movk    x10, #0x3333, lsl #48

        movz    x11, #0x0f0f             // 0x0f0f0f0f0f0f0f0f
        movk    x11, #0x0f0f, lsl #16
        movk    x11, #0x0f0f, lsl #32
        movk    x11, #0x0f0f, lsl #48

        movz    x12, #0x00ff             // 0x00ff00ff00ff00ff
        movk    x12, #0x00ff, lsl #16
        movk    x12, #0x00ff, lsl #32
        movk    x12, #0x00ff, lsl #48

        movz     x13, #0xffff             // 0x0000ffff0000ffff
        movk     x13, #0xffff, lsl #32

        movz     x14, #0xffff             // 0x00000000ffffffff
        movk     x15, #0xffff, lsl #16

        // movz     x10, #3689348814741910323
        // movz     x11, #1085102592571150095
        // movz     x12, #71777214294589695
        // movz     x13, #281470681808895
        // movz     x14, #4294967295

        stur     xzr, [sp, #12]
        stur     x8, [sp]
        ldur     x8, [sp]
        ands     x8, x8, x9
        ldur     x15, [sp]
        lsr     x15, x15, #1
        ands     x9, x15, x9
        adds     x8, x8, x9
        stur     x8, [sp]
        ldur     x8, [sp]
        ands     x8, x8, x10
        ldur     x9, [sp]
        lsr     x9, x9, #2
        ands     x9, x9, x10
        adds     x8, x8, x9
        stur     x8, [sp]
        ldur     x8, [sp]
        ands     x8, x8, x11
        ldur     x9, [sp]
        lsr     x9, x9, #4
        ands     x9, x9, x11
        adds     x8, x8, x9
        stur     x8, [sp]
        ldur     x8, [sp]
        ands     x8, x8, x12
        ldur     x9, [sp]
        lsr     x9, x9, #8
        ands     x9, x9, x12
        adds     x8, x8, x9
        stur     x8, [sp]
        ldur     x8, [sp]
        ands     x8, x8, x13
        ldur     x9, [sp]
        lsr     x9, x9, #16
        ands     x9, x9, x13
        adds     x8, x8, x9
        stur     x8, [sp]
        ldur     x8, [sp]
        ands     x8, x8, x14
        ldur     x9, [sp]
        lsr     x9, x9, #32
        ands     x9, x9, x14
        adds     x8, x8, x9
        stur     x8, [sp]
        ldur     x8, [sp]
        //mov     x0, x8
        add     sp, sp, #16             // =16
        ret
