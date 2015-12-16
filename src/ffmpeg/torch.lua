if not pcall(require, 'torch') then
  error('Torch module must be installed to use ffmpeg.torch')
end

local ffmpeg = require('ffmpeg')
local ffi = require('ffi')
local bit = require('bit')

local PIX_FMT_PLANAR = 16
local PIX_FMT_RGB = 32

function ffmpeg.Video:frame_to_tensor(frame)
  local desc = ffmpeg.libavutil.av_pix_fmt_desc_get(frame.format)
  local is_packed_rgb =
    bit.band(desc.flags, bit.bor(PIX_FMT_PLANAR, PIX_FMT_RGB)) == PIX_FMT_RGB

  local tensor

  if is_packed_rgb then
    -- TODO: Support other packed RGB formats
    assert(ffi.string(ffmpeg.libavutil.av_get_pix_fmt_name(frame.format)) == 'rgb8')

    tensor = torch.ByteTensor(3, frame.height, frame.width)
    tensor:zero()

    for y=1,frame.height do
      for x=1,frame.width do
        local p = (y - 1) * frame.linesize[0] + (x - 1) * 3
        for i=1,3 do
          tensor[i][y][x] = frame.data[0][p + (i - 1)]
        end
      end
    end
  else -- Planar
    -- Calculate number of channels (eg 3 for YUV, 1 for greyscale)
    local n_channels = 4
    for i=3,0,-1 do
      if frame.linesize[i] == 0 then
        n_channels = n_channels - 1
      else
        break
      end
    end

    -- Create a Torch tensor to hold the image
    tensor = torch.ByteTensor(n_channels, frame.height, frame.width)

    -- Fill the tensor
    for i=1,n_channels do
      local stride = frame.linesize[i - 1]
      local channel_data = frame.data[i - 1]
      for y=1,frame.height do
        for x=1,frame.width do
          tensor[i][y][x] = channel_data[(y - 1) * stride + (x - 1)]
        end
      end
    end
  end

  return tensor
end

return ffmpeg
