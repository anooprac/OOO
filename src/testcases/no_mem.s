.arch armv8-a
.global main
.text

main:
movz x0, #0, lsl #0
movk x1, #3
subs x2, x1, x0
add x3, x0, #0x7
and x0, x2, #0x7
ret
