#include <stdio.h>

#include <stdlib.h>
#include <assert.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include "vpi_user.h"

#include "elf.h"
#include "vpi_user.h"
#include "stdint.h"

# define PAGESIZE 4096
# define NUM_PAGES 3

uint32_t text_start_addr_upper;
uint32_t data_start_addr_upper;
uint32_t text_size_upper;
uint32_t data_size_upper;
uint32_t entry_upper;
uint32_t text_start_addr_lower;
uint32_t data_start_addr_lower;
uint32_t text_size_lower;
uint32_t data_size_lower;
uint32_t entry_lower;

uint8_t buffer[PAGESIZE*NUM_PAGES];

void elf_register(void);
void (*vlog_startup_routines[])(void);

static int loadElf(char *userdata) {
    vpiHandle systfref, args_iter, argh;
    struct t_vpi_value argval;
    PLI_BYTE8 *filename;
    uint32_t value;

    systfref = vpi_handle(vpiSysTfCall, NULL);
    args_iter = vpi_iterate(vpiArgument, systfref);


    argval.format = vpiStringVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    filename = argval.value.str;
    // vpi_printf("filename is: %s\n", filename);


    uint64_t tag_array[3];
    // printf("filename is %s\n", filename);
    memset(buffer, 0, PAGESIZE*NUM_PAGES); // each section (data, code, stack) allocated 5 pages
    // Open the file.
    int fd = open(filename, O_RDONLY);
    if (fd < 0) {
        perror(filename);
        exit(-1);
    }

    // printf("found the file!\n");
    
    // Get file stats.
    struct stat statBuffer;
    int rc = fstat(fd, &statBuffer);
    if (rc != 0) {
        perror("stat");
        exit(-1);
    }
    
    // Mmap the file for quick access.
    uintptr_t ptr = (uintptr_t) mmap(0, statBuffer.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if ((void *)ptr == MAP_FAILED) {
        perror("mmap");
        exit(-1);
    }
    
    // Get ELF header information.
    Elf64_Ehdr *header = (Elf64_Ehdr *) ptr;
    assert(header->e_type == ET_EXEC); // Check that it's an executable.
    uint64_t entry = header->e_entry; // Entry point of ELF executable.
    uint64_t entry_size = header->e_phentsize;
    uint64_t entry_count = header->e_phnum;
    
    // Get ELF program header and load segments.
    Elf64_Phdr *progHeader = (Elf64_Phdr *)(ptr + header->e_phoff);
    uint64_t base = 0;
    for (unsigned i = 0; i < entry_count; i++) {
        if (progHeader->p_type == PT_LOAD) {
            uint8_t *dataPtr = (uint8_t *)(ptr + progHeader->p_offset);
            uint64_t vaddr = progHeader->p_vaddr;
            tag_array[i] = vaddr / PAGESIZE;
            //printf("vaddr for this segment is 0x%llx\n", vaddr);
            uint64_t filesz = progHeader->p_filesz;
            //uint64_t memsz = progHeader->p_memsz;
            //printf("memsz is 0x%llx\n", memsz);

            unsigned long v_align = (vaddr % PAGESIZE);
            //unsigned long f_align = filesz + (PAGESIZE - ((filesz + vaddr) % PAGESIZE));

            //int read = !!(progHeader->p_flags & 0x4);
            //int write = !!(progHeader->p_flags & 0x2);
            //int exec = !!(progHeader->p_flags & 0x1);

            // Map data from the file for this segment
            //printf("writing bytes from 0x%llx to 0x%llx\n", (vaddr), (vaddr + filesz + v_align - 1));
            for (uint64_t j = 0; j < filesz + v_align; j++) {
                //uint64_t addr = vaddr + j;
                uint8_t byte = dataPtr[j];
                buffer[base + j] = byte;
            }     
        }
        progHeader = (Elf64_Phdr *) (((uintptr_t) progHeader) + entry_size);
        base += PAGESIZE;
    }

    // Read section header to fill in machine memory segments
    Elf64_Shdr *sectionHeader = (Elf64_Shdr *)(ptr + header->e_shoff);
    entry_size = header->e_shentsize;
    entry_count = header->e_shnum;
    Elf64_Shdr *sectionStrings = (Elf64_Shdr *)((char *)sectionHeader + (header->e_shstrndx*entry_size));
    char *strings = (char *)ptr + sectionStrings->sh_offset;
    for (unsigned i = 0; i < entry_count; i++) {
        char *name = strings + sectionHeader->sh_name;
        uint64_t tag = sectionHeader->sh_addr / PAGESIZE;
        if (!strcmp(name, ".text")) {
            //printf(".text section starts at addres 0x%llx\n", sectionHeader->sh_addr);
            // guest.mem->seg_start_addr[TEXT_SEG] = sectionHeader->sh_addr;
            for (int j = 0; j < 3; j ++) {
                if (tag == tag_array[j]) {
                    //printf("*****text start addr is 0x%llx\n", sectionHeader->sh_addr);
                    text_start_addr_lower = (uint32_t)sectionHeader->sh_addr;
                    text_start_addr_upper = (uint32_t)(sectionHeader->sh_addr >> 32);
                     //printf("*****text size is 0x%llx\n", sectionHeader->sh_size);
                    text_size_lower = (uint32_t)sectionHeader->sh_size;
                    text_size_upper = (uint32_t)(sectionHeader->sh_size >> 32);
                }
            }
        }
        if (!strcmp(name, ".data")) {
            //printf(".data section starts at address 0x%llx\n", sectionHeader->sh_addr);
            // guest.mem->seg_start_addr[DATA_SEG] = sectionHeader->sh_addr;
            for (int j = 0; j < 3; j ++) {
                if (tag == tag_array[j]) {
                   //printf("*****data start addr is 0x%llx\n", sectionHeader->sh_addr);
                    data_start_addr_lower = (uint32_t)sectionHeader->sh_addr;
                    data_start_addr_upper = (uint32_t)(sectionHeader->sh_addr>>32);
                     //printf("*****data size is 0x%llx\n", sectionHeader->sh_size);
                    data_size_lower = (uint32_t)sectionHeader->sh_size;
                    data_size_upper = (uint32_t)(sectionHeader->sh_size>>32);
                }
            }
        }
        sectionHeader = (Elf64_Shdr *) (((uintptr_t) sectionHeader) + entry_size);
    }
    // printf("******entry is 0x%llx\n", entry);

    entry_lower = (uint32_t)entry;
    entry_upper = (uint32_t)(entry>>32);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = text_start_addr_upper;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = text_start_addr_lower;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = data_start_addr_upper;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);
    

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = data_start_addr_lower;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);


    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = text_size_upper;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = text_size_lower;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);


    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = data_size_upper;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = data_size_lower;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = entry_upper;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);

    argval.format = vpiIntVal;
    argh = vpi_scan(args_iter);
    vpi_get_value(argh, &argval);
    value = argval.value.integer;
    argval.value.integer = entry_lower;;
    vpi_put_value(argh, &argval, NULL, vpiNoDelay);
    if (value && userdata && 0 ) {
        // do something meaningless to supress warning
    }
    
    vpi_free_object(args_iter);


    // pipe the sections to a file
    FILE *fp = fopen("elf/elf_sections.txt", "w");
    // fwrite(buffer, sizeof(buffer[0]), sizeof(buffer), fp);
    for (int i = 0; i < (PAGESIZE * NUM_PAGES); i ++) {
        uint8_t val = buffer[i];
        for (int j = 7; j >= 0; j --) {
            fprintf(fp, "%d", (val >> j) & 1);
        }
        fprintf(fp, "\n");
    }
    fclose(fp);

    return 0;
}

void elf_register(void)
{
      s_vpi_systf_data tf_data;

      tf_data.type      = vpiSysTask;
      tf_data.tfname    = "$elf";
      tf_data.calltf    = loadElf;
      tf_data.compiletf = 0;
      tf_data.sizetf    = 0;
      tf_data.user_data = 0;
      vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
  elf_register,
  0
};