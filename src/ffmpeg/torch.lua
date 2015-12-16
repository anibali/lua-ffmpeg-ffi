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
    assert(ffi.string(ffmpeg.libavutil.av_get_pix_fmt_name(frame.format)) == 'rgb24')

    -- Create a Torch tensor to hold the image
    tensor = torch.ByteTensor(3, frame.height, frame.width)

    -- Fill the tensor
    local ptr = torch.data(tensor)
    local pos = 0
    local y_max = frame.height - 1
    local triple_x_max = (frame.width - 1) * 3
    for i=0,2 do
      for y=0,y_max do
        local offset = y * frame.linesize[0] + i
        for triple_x=0,triple_x_max,3 do
          ptr[pos] = frame.data[0][offset + triple_x]
          pos = pos + 1
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
    local ptr = torch.data(tensor)
    local pos = 0
    local y_max = frame.height - 1
    local x_max = frame.width - 1
    for i=0,(n_channels-1) do
      local stride = frame.linesize[i]
      local channel_data = frame.data[i]
      for y=0,y_max do
        local offset = stride * y
        for x=0,x_max do
          ptr[pos] = channel_data[offset + x]
          pos = pos + 1
        end
      end
    end
  end

  return tensor
end

return ffmpeg
