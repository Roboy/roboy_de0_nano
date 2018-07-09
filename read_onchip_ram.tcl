# open service to jtag uart master
open_service master [get_service_paths master]
# check if service is open
is_service_open master [get_service_paths master]
# read 300 byte values from on-chip memory address 0x0
master_read_8 [get_service_paths master] 0x0 300