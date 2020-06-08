## List all NDI sources on the network
ffmpeg -f libndi_newtek -find_sources 1 -i dummy

## Monitor an NDI stream
ffplay -f libndi_newtek -i "LAPTOP (RearCamera)"
