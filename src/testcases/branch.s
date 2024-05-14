.arch armv8-a
.global main
.text

main:
    movz x1, #5
label: 
    movz x2, #1
    subs x1, x1, x2
    cbnz x1, label
label2:
    add x3, x2, #2