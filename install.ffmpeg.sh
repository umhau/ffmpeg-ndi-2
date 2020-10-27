#!/bin/sh
set -ve                 # display what's happening as it happens and exit on error

# This script will prepare - compile and install ffmpeg with NDI.

# Environment:
InstallDir=$PWD

cores="$1"
echo "using make with $cores cores"

[ "`whoami`" != "root" ] && echo "must run as root. exiting." && exit

# Update Ubuntu:
echo "Updating Ubuntu"

sudo apt-get update
sudo apt-get -y upgrade

# Resize Ubuntu network system buffer: 
# (to avoid h264 blur and other network related problems)
echo "Resize Ubuntu network system buffer"

sudo sysctl -w net.core.rmem_max=8388608
sudo sysctl -w net.core.wmem_max=8388608
sudo sysctl -w net.core.rmem_default=65536
sudo sysctl -w net.core.wmem_default=65536
sudo sysctl -w net.ipv4.tcp_rmem='4096 87380 8388608'
sudo sysctl -w net.ipv4.tcp_wmem='4096 65536 8388608'
sudo sysctl -w net.ipv4.tcp_mem='8388608 8388608 8388608'
sudo sysctl -w net.ipv4.route.flush=1

# Dependencies for Ubuntu
sudo apt install -y xterm

# Dependencies for FFmpeg:
echo "Dependencies for FFmpeg"
sudo apt-get -y install autoconf automake build-essential cmake git libass-dev libfreetype6-dev libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev mercurial pkg-config texinfo wget zlib1g-dev yasm libx264-dev libx265-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev libopencore-amrnb-dev libopencore-amrwb-dev librtmp-dev 

# Avahi / Bonjour: without this, ffmpeg w/ ndi can't find local network video stream sources
sudo apt-get -y install avahi-utils

# NDI SDK:
echo "NDI SDK"

cd $InstallDir/NDI-SDK
sudo chmod +x InstallNDISDK_v3_Linux.sh
sudo ./InstallNDISDK_v3_Linux.sh

# Move files from NDI SDK:
mkdir ~/ffmpeg_sources
mkdir ~/ffmpeg_sources/ndi
cd ~/ffmpeg_sources/ndi
mv  "$InstallDir/NDI-SDK/NDI SDK for Linux/include" .
mv  "$InstallDir/NDI-SDK/NDI SDK for Linux/lib/x86_64-linux-gnu" ./lib
cd $HOME

# Move and activate NDI configfile: 
echo "Move and activate NDI configfile"

sudo mv $InstallDir/NDI-SDK/NDI.conf /etc/ld.so.conf.d/NDI.conf
sudo ldconfig

#Get FFmpeg:
echo "Get FFmpeg"

cd $HOME
#FFMPEG removed libndi - https://git.ffmpeg.org/gitweb/ffmpeg.git/commit/4b32f8b3ebfa011fcc5991bcaa97c3f5b61b49ad
git clone https://github.com/FFmpeg/FFmpeg/ --branch=n4.1.1 ffmpeg

#Compile:
echo "Compile FFmpeg"

mkdir $HOME/ffmpeg_build
mkdir $HOME/ffmpeg_build/lib 
mkdir $HOME/ffmpeg_build/lib/pkgconfig
PATH=$HOME/bin:$PATH
PKG_CONFIG_PATH=$HOME/ffmpeg_build/lib/pkgconfig
cd $HOME/ffmpeg
./configure  --prefix=$HOME/ffmpeg_build  --pkg-config-flags=--static  --extra-cflags=-I$HOME/ffmpeg_sources/ndi/include  --extra-ldflags=-L$HOME/ffmpeg_sources/ndi/lib  --bindir=$HOME/bin --enable-ffplay --enable-gpl  --enable-libass  --enable-libfdk-aac  --enable-libfreetype  --enable-libmp3lame  --enable-libopencore-amrnb   --enable-libopencore-amrwb  --disable-librtmp   --enable-libopus   --enable-libtheora   --enable-libvorbis   --enable-libvpx   --enable-libx264 --enable-nonfree   --enable-version3 --enable-libndi_newtek 

if   [ -z $cores ]; then 
  make
else 
  make -j $cores
fi

sudo make install

# put the libraries where they go
sudo install ~/ffmpeg_sources/ndi/lib/* /usr/lib/

sudo install ~/bin/ffmpeg /usr/bin/ffmpeg_ndi

#Finished:
echo "-------------------------------------------------------------"
echo
echo "Reboot"
