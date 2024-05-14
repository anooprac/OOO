.text
.global main
main:
    mov x0, #0x1000          // Set base address in X0
    movk x0, #0x1234, lsl #16 // Move with keep to set upper half of X0

    // Store a value using STUR
    mov x1, #5              // Load immediate value into X1
    stur x1, [x0, #8]       // Store value 5 at base address + 8

    // Load the stored value using LDUR
    ldur x2, [x0, #8]       // Load from memory base address + 8 into X2

    // Use LDP to load pair of registers
    stp x1, x2, [x0, #16]   // Store X1 and X2 at base address + 16
    ldp x3, x4, [x0, #16]   // Load into X3 and X4 from base address + 16

    adds x5, x3, x4          // Add X3 and X4 store result in X5

    ret                      // Return from main function