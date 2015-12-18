# ffmpeg-ffi

LuaJIT FFI bindings to FFmpeg libraries.

## Usage

    local ffmpeg = require('ffmpeg')

    ffmpeg.new('./example.mpg')
      :filter('gray', 'scale=40:12')
      :read_video_frame()
      :to_ascii()
      :and_then(function(ascii_frame)
        print(ascii_frame)
      end)
      :catch(function(err)
        print('An error occurred: ' .. err)
      end)

### Torch

If you have Torch installed, load the enhanced version of the library.

    local ffmpeg = require('ffmpeg.torch')

    local first_frame_tensor = ffmpeg.new('./example.mpg')
      :filter('rgb24', 'scale=512:512')
      :read_video_frame()
      :to_byte_tensor()
      :catch(function(err)
        -- Use the Lena image in case of error
        return image:lena()
      end)
      :get()
