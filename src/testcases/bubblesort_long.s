.arch armv8-a
.global main
.text


bubbleSort:                             // @bubbleSort
        sub     sp, sp, #48
        stur     x0, [sp, #40]
        stur     x1, [sp, #32]
        stur     xzr, [sp, #24]
        b       .LBB0_1
.LBB0_1:                                // =>This Loop Header: Depth=1
        ldur     x8, [sp, #24]
        ldur     x9, [sp, #32]
        sub     x9, x9, #1
        subs    x8, x8, x9
        b.ge    .LBB0_10
        b       .LBB0_2
.LBB0_2:                                //   in Loop: Header=BB0_1 Depth=1
        stur     xzr, [sp, #16]
        b       .LBB0_3
.LBB0_3:                                //   Parent Loop BB0_1 Depth=1
        ldur     x8, [sp, #16]
        ldur     x9, [sp, #32]
        ldur     x10, [sp, #24]
        subs    x9, x9, x10
        sub    x9, x9, #1
        subs    x8, x8, x9
        b.ge    .LBB0_8
        b       .LBB0_4
.LBB0_4:                                //   in Loop: Header=BB0_3 Depth=2
        ldur     x8, [sp, #40]
        ldur     x9, [sp, #16]
        lsl     x9, x9, #3
        adds     x10, x8, x9
        ldur     x8, [x10]
        ldur     x9, [sp, #40]
        ldur     x10, [sp, #16]
        add     x10, x10, #1
        lsl     x10, x10, #3
        adds     x11, x9, x10
        ldur     x9, [x11]
        subs    x8, x8, x9
        b.le    .LBB0_6
        b       .LBB0_5
.LBB0_5:                                //   in Loop: Header=BB0_3 Depth=2
        ldur     x8, [sp, #40]
        ldur     x9, [sp, #16]
        lsl     x9, x9, #3
        adds     x10, x8, x9
        ldur     x8, [x10]
        stur     x8, [sp, #8]
        ldur     x8, [sp, #40]
        ldur     x9, [sp, #16]
        add     x9, x9, #1
        lsl     x9, x9, #3
        adds     x10, x8, x9
        ldur     x8, [x10]
        ldur     x9, [sp, #40]
        ldur     x10, [sp, #16]
        lsl     x10, x10, #3
        adds     x11, x9, x10
        stur     x8, [x11]
        ldur     x8, [sp, #8]
        ldur     x9, [sp, #40]
        ldur     x10, [sp, #16]
        add     x10, x10, #1
        lsl     x10, x10, #3
        adds     x11, x9, x10
        stur     x8, [x11]
        b       .LBB0_6
.LBB0_6:                                //   in Loop: Header=BB0_3 Depth=2
        b       .LBB0_7
.LBB0_7:                                //   in Loop: Header=BB0_3 Depth=2
        ldur     x8, [sp, #16]
        add     x8, x8, #1
        stur     x8, [sp, #16]
        b       .LBB0_3
.LBB0_8:                                //   in Loop: Header=BB0_1 Depth=1
        b       .LBB0_9
.LBB0_9:                                //   in Loop: Header=BB0_1 Depth=1
        ldur     x8, [sp, #24]
        add     x8, x8, #1
        stur     x8, [sp, #24]
        b       .LBB0_1
.LBB0_10:
        add     sp, sp, #48
        ret
main:                                   // @main
        stp     x29, x30, [sp, #-16]
        sub     sp, sp, #16
        //stp     x29, x30, [sp, #-16]!           // 16-byte Folded Spill
        //movz     x29, sp
        add     x29, sp, #1
        sub     x29, x29, #1
        sub     sp, sp, #48
        stur    xzr, [x29, #-4]
        movz     x8, #100                        // =0x64
        stur    x8, [x29, #-16]
        ldur    x8, [x29, #-16]
        //mov     x9, sp
        add     x9, sp, #1
        sub     x9, x9, #1
        stur    x9, [x29, #-24]
        lsl     x9, x8, #3
        add     x9, x9, #15
        and     x10, x9, #0xfffffffffffffff0
        //mov     x9, sp
        add     x9, sp, #1
        sub     x9, x9, #1
        subs    x9, x9, x10
        //mov     sp, x9
        add     sp, x9, #1
        sub     sp, sp, #1
        stur    x9, [x29, #-48]                 // 8-byte Folded Spill
        stur    x8, [x29, #-32]
        stur    xzr, [x29, #-40]
        b       .LBB1_1
.LBB1_1:                                // =>This Inner Loop Header: Depth=1
        ldur    x8, [x29, #-40]
        ldur    x9, [x29, #-16]
        subs    x8, x8, x9
        b.ge    .LBB1_4
        b       .LBB1_2
.LBB1_2:                                //   in Loop: Header=BB1_1 Depth=1
        ldur    x9, [x29, #-48]                 // 8-byte Folded Reload
        ldur    x8, [x29, #-16]
        ldur    x10, [x29, #-40]
        subs    x8, x8, x10
        ldur    x10, [x29, #-40]
        lsl     x11, x10, #3
        adds    x11, x9, x11
        stur     x8, [x11]
        //stur     x8, [x9, x10, lsl #3]
        b       .LBB1_3
.LBB1_3:                                //   in Loop: Header=BB1_1 Depth=1
        ldur    x8, [x29, #-40]
        add     x8, x8, #1
        stur    x8, [x29, #-40]
        b       .LBB1_1
.LBB1_4:
        ldur    x0, [x29, #-48]                 // 8-byte Folded Reload
        ldur    x1, [x29, #-16]
        bl      bubbleSort
        stur    xzr, [x29, #-4]
        ldur    x8, [x29, #-24]
        //mov     sp, x8
        add     sp, x8, #1
        sub     sp, sp, #1
        ldur    x0, [x29, #-4]
        //mov     sp, x29
        add     sp, x29, #1
        sub     sp, sp, #1
        ldp     x29, x30, [sp]
        add     sp, sp, #16     
        //ldp     x29, x30, [sp], #16             // 16-byte Folded Reload
        ret
