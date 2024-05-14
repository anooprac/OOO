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
        sub     sp, sp, #80
        stp     x29, x30, [sp, #64]             // 16-byte Folded Spill
        add     x29, sp, #64
        movz     x8, #0
        stur     x8, [sp, #12]                   // 4-byte Folded Spill
        stur    xzr, [x29, #-4]
        add     x0, sp, #16
        movz     x1, #5                         // ARRAY SIZE
        movz     x8, #6                         // =0x5 ARRAY VALS
        stur     x8, [sp, #16]
        movz     x8, #3                          // =0x4
        stur     x8, [sp, #24]
        movz     x8, #27                          // =0x3
        stur     x8, [sp, #32]
        movz     x8, #2                          // =0x2
        stur     x8, [sp, #40]
        movz     x8, #9                          // =0x1
        stur     x8, [sp, #48]
        bl      bubbleSort
        ldur     x0, [sp, #12]                   // 4-byte Folded Reload
        ldp     x29, x30, [sp, #64]             // 16-byte Folded Reload
        add     sp, sp, #80
        ret
        