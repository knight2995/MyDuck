@echo on
nasm .\BootLoader\boot.asm -f bin -o .\BootLoader\boot.bin
nasm .\KernelLoader\Kernel.asm -f bin -o .\KernelLoader\KernelL.bin
copy .\BootLoader\boot.bin + .\KernelLoader\KernelL.bin + .\Kernel\kernel.exe /b .\OS\os.bin
pause
exit