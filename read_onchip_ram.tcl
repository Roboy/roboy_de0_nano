# open service to jtag uart master
open_service master [get_service_paths master]
# check if service is open
is_service_open master [get_service_paths master]
# read 300 byte values from on-chip memory address 0x0
master_read_16 [get_service_paths master] 0x0 300
# setup dashboard
set dash [add_service dashboard dashboard_example "Dashboard Example" "Tools/Example"]
# start dashboard
dashboard_set_property $dash self visible true
# read to file
master_read_to_file [get_service_paths master] test_pattern.bin 0x0 4096
