;minimalist resource-based dropper. finds a resource, writes it to file, executes it.

%include '..\..\standard_hdr.asm'

EntryPoint:
    push RT_RCDATA              ; lpType
    push ares                   ; lpName
    push 0                      ; hModule
    call FindResourceA
    mov [hResInfo], eax

    ; as if we didn't have the size already
    push eax                    ; HRSRC hResInfo
    push 0                      ; HMODULE hModule
    call SizeofResource
    mov [resource_size], eax

    push dword [hResInfo]       ; hResInfo
    push 0                      ; hModule
    call LoadResource
    mov [hResData], eax

    push eax                    ; hResData
    call LockResource
    mov [lpResource], eax

    push 0                            ; hTemplateFile
    push 0                            ; dwFlagsAndAttributes
    push CREATE_NEW                   ; dwCreationDisposition
    push 0                            ; lpSecurityAttributes
    push FILE_SHARE_READ              ; dwShareMode
    push GENERIC_READ | GENERIC_WRITE ; dwDesiredAccess
    push tempfile                     ; lpFileName      typically droppers do it in temporary directory, via GetTempPath
    call CreateFileA
    mov [hFile], eax

    push 0                          ; lpOverLapped
    push lpNumberOfBytesWritten     ; lpNumberOfBytesWritten
    push dword [resource_size]      ; nNumberOfBytesToWrite
    push dword [lpResource]         ; lpBuffer
    push dword [hFile]              ; hFile
    call WriteFile

    push dword [hFile]    ; hObject
    call CloseHandle

    push lpProcessInformation   ; lpProcessInformation
    push lpStartupInfo          ; lpStartupInfo
    push 0                      ; lpCurrentDirectory
    push 0                      ; lpEnvironment
    push 0                      ; dwCreationFlags
    push 0                      ; bInheritHandles
    push 0                      ; lpThreadAttributes
    push 0                      ; lpProcessAttributes
    push 0                      ; lpCommandLine
    push tempfile               ; lpApplicationName
    call CreateProcessA

    ; waiting for the thread to end
    push -1                                                         ; DWORD dwMilliseconds
    push dword [lpProcessInformation + PROCESS_INFORMATION.hThread] ; HANDLE hHandle
    call WaitForSingleObject

    ; repeatedly try and delete the file
delete_loop:
    push tempfile              ; lpFileName
    call DeleteFileA
    test eax, eax
    jz delete_loop

    push 0                      ; uExitCode
    call ExitProcess

;%IMPORT kernel32.dll!FindResourceA
;%IMPORT kernel32.dll!LoadResource
;%IMPORT kernel32.dll!LockResource
;%IMPORT kernel32.dll!SizeofResource

;%IMPORT kernel32.dll!CreateFileA
;%IMPORT kernel32.dll!WriteFile
;%IMPORT kernel32.dll!CloseHandle
;%IMPORT kernel32.dll!DeleteFileA

;%IMPORT kernel32.dll!CreateProcessA
;%IMPORT kernel32.dll!WaitForSingleObject

;%IMPORT kernel32.dll!ExitProcess

SIZEOFCODE equ $ - base_of_code

;%IMPORTS

align 16, db 0
base_of_data:

ares db "#101", 0
tempfile db 'tempfile.exe', 0

align 16, db 0
hResInfo dd 0
resource_size dd 0 ; could be generated by the assembler
hResData dd 0
lpResource dd 0
hFile dd 0
lpNumberOfBytesWritten dd 0

align 16, db 0
lpStartupInfo istruc STARTUPINFO
iend

align 16, db 0
lpProcessInformation istruc PROCESS_INFORMATION
iend

SIZEOFINITIALIZEDDATA equ $ - base_of_data

; root directory
Directory_Entry_Resource:
resource_directory:
    .Characteristics      dd 0
    .TimeDateStamp        dd 0
    .MajorVersion         dw 0
    .MinorVersion         dw 0
    .NumberOfNamedEntries dw 0
    .NumberOfIdEntries    dw 1

IMAGE_RESOURCE_DIRECTORY_ENTRY_1:
    .ID dd RT_RCDATA    ; .. resource type of that directory
    .OffsetToData dd IMAGE_RESOURCE_DATA_IS_DIRECTORY | (resource_directory_01 - resource_directory)

; type subdirectory
resource_directory_01:
    .Characteristics      dd 0
    .TimeDateStamp        dd 0
    .MajorVersion         dw 0
    .MinorVersion         dw 0
    .NumberOfNamedEntries dw 0
    .NumberOfIdEntries    dw 1
IMAGE_RESOURCE_DIRECTORY_ENTRY_01:
    .ID dd 101  ; name of the underneath resource
    .OffsetToData dd IMAGE_RESOURCE_DATA_IS_DIRECTORY | (resource_directory_001 - resource_directory)

; resource subdirectory
resource_directory_001:
    .Characteristics      dd 0
    .TimeDateStamp        dd 0
    .MajorVersion         dw 0
    .MinorVersion         dw 0
    .NumberOfNamedEntries dw 0
    .NumberOfIdEntries    dw 1

IMAGE_RESOURCE_DIRECTORY_ENTRY_001:
    .ID dd 0    ; unused ?
    .OffsetToData dd IMAGE_RESOURCE_DATA_ENTRY_101 - resource_directory

IMAGE_RESOURCE_DATA_ENTRY_101:
    OffsetToData dd resource_data - IMAGEBASE
    Size1 dd        RESOURCE_SIZE
    CodePage dd     0
    Reserved dd     0

;resname db 'EMBEDDED_PE', 0 ; can't get it working by name now :/
resource_data:
incbin '..\pe\helloworld.exe'
RESOURCE_SIZE equ $ - resource_data

DIRECTORY_ENTRY_RESOURCE_SIZE equ $ - Directory_Entry_Resource

uninit_data equ IMAGEBASE
SIZEOFUNINITIALIZEDDATA equ 0
Section0Size EQU $ - Section0Start

SIZEOFIMAGE EQU $ - IMAGEBASE

;Ange Albertini, Creative Commons BY, 2010