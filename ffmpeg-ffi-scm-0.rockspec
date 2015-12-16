package = "ffmpeg-ffi"
version = "scm-0"

source = {
  url = "https://github.com/anibali/lua-ffmpeg-ffi/archive/master.zip",
  dir = "lua-ffmpeg-ffi-master"
}

description = {
  summary = "LuaJIT FFI bindings to FFMpeg libraries",
  detailed = [[
    This module provides LuaJIT FFI bindings to FFMpeg libraries for processing
    videos
  ]],
  homepage = "https://github.com/anibali/lua-ffmpeg-ffi",
  license = "MIT <http://opensource.org/licenses/MIT>"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["ffmpeg"] = "src/ffmpeg/init.lua",
    ["ffmpeg.torch"] = "src/ffmpeg/torch.lua"
  }
}
