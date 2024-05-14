.arch armv8-a
.global main
.text

main:
    movz x0, #0, lsl #0
    movk x1, #2
    movk x2, #0
    sub x2, x2, #3
    lsl x3, x1, #3 
    lsr x4, x1, #1
    asr x5, x2, #2
    ret
