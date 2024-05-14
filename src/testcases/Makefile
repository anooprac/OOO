build-all:
	aarch64-elf-gcc all.s -o all -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 all > all.elf
	objdump -d all > all.objdump

build-imm:
	aarch64-elf-gcc imm.s -o imm -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 imm > imm.elf
	objdump -d imm > imm.objdump

build-no-mem:
	aarch64-elf-gcc no_mem.s -o no_mem -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 no_mem > no_mem.elf
	objdump -d no_mem > no_mem.objdump

build-hard-instrs:
	aarch64-elf-gcc hard_instrs.s -o hard_instrs -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 hard_instrs > hard_instrs.elf
	objdump -d hard_instrs > hard_instrs.objdump

build-testasm-linux:
	aarch64-linux-gnu-gcc testasm.s -o testasm -nostartfiles -nostdlib -O0 --entry=main
	readelf -a --hex-dump=1 --hex-dump=2 testasm > testasm.elf

build-mem:
	aarch64-elf-gcc mem.s -o mem -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 mem > mem.elf
	objdump -d mem > mem.objdump

build-branch:
	aarch64-elf-gcc branch.s -o branch -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 branch > branch.elf
	objdump -d branch > branch.objdump

build-bubblesort:
	aarch64-elf-gcc bubblesort.s -o bubblesort -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 bubblesort > bubblesort.elf
	objdump -d bubblesort > bubblesort.objdump

build-popcount:
	aarch64-elf-gcc popcount.s -o popcount -nostartfiles -nostdlib -O0 --entry=main
	greadelf -a --hex-dump=1 --hex-dump=2 popcount > popcount.elf
	objdump -d popcount > popcount.objdump