# default partition layout EFI Boot Guard usage

# EFI partition containing efibootguard bootloader binary
part --source efibootguard-efi  --size 16M --extra-space 0 --overhead-factor 1 --label efi   --align 1024 --part-type=EF00 --active --fsuuid 0x4321dcba

# EFI Boot Guard environment/config partitions plus Kernel files
part --source efibootguard-boot --size 32M --extra-space 0 --overhead-factor 1 --label BOOT0 --align 1024 --part-type=0700 --sourceparams "revision=2" --fsuuid 0x4321dcbb
part --source efibootguard-boot --size 32M --extra-space 0 --overhead-factor 1 --label BOOT1 --align 1024 --part-type=0700 --sourceparams "revision=1" --fsuuid 0x4321dcbc
