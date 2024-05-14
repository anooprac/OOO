default: build-elf build-cpu run

all: build-elf build-cpu run wave

build-elf:
	$(MAKE) -C elf build
build-no-mem:
	$(MAKE) -C testcases build-no-mem
build-mem:
	$(MAKE) -C testcases build-mem
build-branch:
	$(MAKE) -C testcases build-branch
build-bubblesort:
	$(MAKE) -C testcases build-bubblesort
build-popcount:
	$(MAKE) -C testcases build-popcount
build-cpu:
	mkdir -p out
	iverilog -g2012 -o out/ooo.vvp ooo_tb.sv ooo_cpu.sv
run:
	mkdir -p log
	vvp -M. -melf/elf out/ooo.vvp > log/log.txt
	grep -vE '^(VCD| *using existing file)' log/log.txt > log/cleaned_log.txt
	grep -vE '^(VCD| *using existing file)' log/log.txt | grep "TO MEMORY" > log/mem_log.txt


wave:
	gtkwave out/ooo_cpu.vcd &
clean:
	$(MAKE) -C elf clean
	rm -f out/*
	rm -f log/*


