# default partition layout EFI Boot Guard usage

# EFI partition containing efibootguard bootloader binary
part --source efibootguard-efi  --fixed-size 16M --label efi   --align 1024 --part-type=EF00 --active --fsuuid 0x4321dcba --uuid c19e7e9f-bacf-49a6-b43d-2fc18d2a8d03

# EFI Boot Guard environment/config partitions plus Kernel files
part --source efibootguard-boot --fixed-size 64M --label BOOT0 --align 1024 --part-type=0700 --sourceparams "revision=2,abrootfs_root=y" --fsuuid 0x4321dcbb --uuid e8567692-2dfa-459a-be15-f6e5ddcc8f49
part --source efibootguard-boot --fixed-size 64M --label BOOT1 --align 1024 --part-type=0700 --sourceparams "revision=1,abrootfs_root=y" --fsuuid 0x4321dcbc --uuid 94b2174d-c792-4e8e-8a34-b506e2927937
