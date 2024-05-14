.arch armv8-a
.global main
.text

main:                                   // @main
        sub     sp, sp, #32
        mov     x8, #1                          // =0x1
        stur     x8, [sp]
        mov     x8, #2                          // =0x2
        stur     x8, [sp, #8]
        mov     x8, #3                          // =0x3
        stur     x8, [sp, #16]
        mov     x8, #4                          // =0x4
        stur     x8, [sp, #24]
        ldur     x8, [sp]
        add     x8, x8, #3
        stur     x8, [sp]
        ldur     x8, [sp, #8]
        add     x8, x8, #3
        stur     x8, [sp, #8]
        ldur     x8, [sp, #16]
        add     x8, x8, #3
        stur     x8, [sp, #16]
        ldur     x8, [sp, #24]
        add     x8, x8, #3
        stur     x8, [sp, #24]
        add     sp, sp, #32
        ret