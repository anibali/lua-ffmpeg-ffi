FROM ubuntu:14.04

# Install build tools
RUN apt-get update \
    && apt-get install -y build-essential git

# Install OpenBLAS
RUN apt-get update \
    && apt-get install -y gfortran
RUN git clone https://github.com/xianyi/OpenBLAS.git /tmp/OpenBLAS \
    && cd /tmp/OpenBLAS \
    && [ $(getconf _NPROCESSORS_ONLN) = 1 ] && export USE_OPENMP=0 || export USE_OPENMP=1 \
    && make NO_AFFINITY=1 \
    && make install \
    && rm -rf /tmp/OpenBLAS

# Install Torch
RUN apt-get update \
    && apt-get install -y cmake curl unzip libreadline-dev libjpeg-dev \
    libpng-dev ncurses-dev imagemagick gnuplot gnuplot-x11 libssl-dev \
    libzmq3-dev graphviz
RUN git clone https://github.com/torch/distro.git ~/torch --recursive \
    && cd ~/torch \
    && ./install.sh

# Export environment variables manually
ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/root/torch/install/share/lua/5.1/?.lua;/root/torch/install/share/lua/5.1/?/init.lua;./?.lua;/root/torch/install/share/luajit-2.1.0-alpha/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua' \
    LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/root/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so' \
    PATH=/root/torch/install/bin:$PATH \
    LD_LIBRARY_PATH=/root/torch/install/lib:$LD_LIBRARY_PATH \
    DYLD_LIBRARY_PATH=/root/torch/install/lib:$DYLD_LIBRARY_PATH

# Install required dependencies for ffmpeg.lua
RUN echo "deb http://ppa.launchpad.net/kirillshkrogalev/ffmpeg-next/ubuntu trusty main" \
    > /etc/apt/sources.list.d/ffmpeg.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8EFE5982
RUN apt-get update \
    && apt-get install -y \
    cpp \
    libavformat-ffmpeg-dev \
    libavcodec-ffmpeg-dev \
    libavutil-ffmpeg-dev \
    libavfilter-ffmpeg-dev

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install busted for running tests
RUN luarocks install busted

# Make working directory for this project
RUN mkdir -p /app/test
WORKDIR /app

# Download test data
COPY ./test/download_test_data.sh /app/test/
RUN cd test && ./download_test_data.sh

COPY ./test/* /app/test/
COPY ./src /app/src
