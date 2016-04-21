####################################################
# 빌드 환경 및 규칙 설정
####################################################
NASM32 = nasm
GCC32 = x86_64-pc-linux-gcc.exe -c -m32 -ffreestanding
LD32 = x86_64-pc-linux-ld.exe -melf_i386 -T ../elf_i386.x -nostdlib -e Main -Ttext 0x10200
OBJCOPY32 = x86_64-pc-linux-objcopy -j .text -j .data -j .rodata -j .bss -S -O binary

OBJECTDIRECTORY = Temp
SOURCEDIRECTORY = Source

####################################################
# 빌드 환경 및 빌드 방법 설정
####################################################
all: prepare Kernel32.bin

prepare:
	mkdir -p $(OBJECTDIRECTORY)

$(OBJECTDIRECTORY)/EntryPoint.bin: $(SOURCEDIRECTORY)/EntryPoint.s
	$(NASM32) -o $@ $<

# 커널의 c소스 파일에 대한 의존성 정보 생성
dep:
	@echo === Make Dependancy File ===
	make -C $(OBJECTDIRECTORY) -f ../makefile InternalDependency
	@echo === Dependancy Search Complete ===

# 디렉터리를 오브젝트 파일 디렉터리로 이동해서 의존성 파일 및 실행 파일 생성
ExecuteInternalBuild: dep
	make -C $(OBJECTDIRECTORY) -f ../makefile Kernel32.elf

# 커널 이미지를 바이너리 파일로 변환
$(OBJECTDIRECTORY)/Kernel32.elf.bin: ExecuteInternalBuild
	$(OBJCOPY32) $(OBJECTDIRECTORY)/Kernel32.elf $@

# 엔트리 포인트와 커널을 합쳐서 보호 모드 바이너리 생성
Kernel32.bin: $(OBJECTDIRECTORY)/EntryPoint.bin $(OBJECTDIRECTORY)/Kernel32.elf.bin
	cat $^ > $@

clean:
	rm -f *.bin
	rm -f $(OBJECTDIRECTORY)/*.*

####################################################
# Make에 의해 다시 호출되는 부분, Temp 디렉터리를 기준으로 수행됨
####################################################
CENTRYPOINTOBJECTFILE = Main.o
CSOURCEFILES = $(wildcard ../$(SOURCEDIRECTORY)/*.c)
ASSEMBLYSOURCEFILES = $(wildcard ../$(SOURCEDIRECTORY)/*.asm)
COBJECTFILES = $(subst Main.o, , $(notdir $(patsubst %.c, %.o, $(CSOURCEFILES))))
ASSEMBLYOBJECTFILES = $(notdir $(patsubst %.asm, %.o, $(ASSEMBLYSOURCEFILES)))

# .c 파일을 .o 파일로 바꾸는 규칙 정의
%.o: ../$(SOURCEDIRECTORY)/%.c
	$(GCC32) -c $<

# .asm 파일을 .o 파일로 바꾸는 규칙 정의
%.o: ../$(SOURCEDIRECTORY)/%.asm
	$(NASM32) -f elf32 -o $@ $<

# 실제 의존성에 관련된 파일 생성
InternalDependency:
	$(GCC32) -MM $(CSOURCEFILES) > Dependency.dep

# 실제 커널 이미지 빌드
Kernel32.elf: $(CENTRYPOINTOBJECTFILE) $(COBJECTFILES) $(ASSEMBLYOBJECTFILES)
	$(LD32) -o $@ $^

# 현재 디렉토리의 파일 중 dependency 파일이 있으면 make에 포함
ifeq (Dependency.dep, $(wildcard Dependency.dep))
include Dependency.dep
endif
