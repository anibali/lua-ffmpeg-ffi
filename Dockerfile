FROM anibali/alpine-tini:3.2

# Install build dependencies
RUN apk add --update \
    build-base cmake git libffi ca-certificates wget curl unzip \
    && rm -rf /var/cache/apk/*

# Install LuaJIT and LuaRocks (with Torch repo enabled)
RUN git clone https://github.com/torch/luajit-rocks.git /tmp/luajit-rocks
RUN cd /tmp/luajit-rocks \
    && cmake . -DCMAKE_INSTALL_PREFIX="/opt/luajit-rocks" -DCMAKE_BUILD_TYPE=Release -DWITH_LUAJIT21=ON \
    && make \
    && make install \
    && rm -rf /tmp/luajit-rocks

# Export environment variables manually
ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/opt/luajit-rocks/share/lua/5.1/?.lua;/opt/luajit-rocks/share/lua/5.1/?/init.lua;./?.lua;/opt/luajit-rocks/share/luajit-2.1.0-alpha/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua' \
    LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/opt/luajit-rocks/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so' \
    PATH=/opt/luajit-rocks/bin:$PATH \
    LD_LIBRARY_PATH=/opt/luajit-rocks/lib:$LD_LIBRARY_PATH \
    DYLD_LIBRARY_PATH=/opt/luajit-rocks/lib:$DYLD_LIBRARY_PATH

# Install libraries for ffmpeg
RUN apk add --update \
    ffmpeg-libs \
    && rm -rf /var/cache/apk/*

# Install required Lua modules
RUN luarocks install busted

# Make working directory for this project
RUN mkdir -p /app/test
WORKDIR /app

# Download test data
COPY ./test/download_test_data.sh /app/test/
RUN cd test && ./download_test_data.sh

COPY ./test/* /app/test/
COPY ./src /app/src
