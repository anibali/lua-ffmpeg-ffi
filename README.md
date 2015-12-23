# ffmpeg-ffi

LuaJIT FFI bindings to FFmpeg libraries.

## Usage

    local ffmpeg = require('ffmpeg')

    local ascii_frame = ffmpeg.new('./example.mpg')
      :filter('gray', 'scale=40:12')
      :read_video_frame()
      :to_ascii()

    print(ascii_frame)

### Torch

If you have Torch installed, load the enhanced version of the library.

    local ffmpeg = require('ffmpeg.torch')

    local byte_tensor = ffmpeg.new('./example.mpg')
      :filter('rgb24', 'scale=512:512')
      :read_video_frame()
      :to_byte_tensor()

    local float_tensor = first_frame_tensor:float():div(255)
