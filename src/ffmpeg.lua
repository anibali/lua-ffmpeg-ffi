local ffi = require('ffi')
require('./cdef')

M = {}

local Video = {}

local function load_lib(t)
  local err = ''
  for _, name in ipairs(t) do
    local ok, mod = pcall(ffi.load, name)
    if ok then return mod, name end
    err = err .. '\n' .. mod
  end
  error(err)
end

local libavformat = load_lib{
  'libavformat-ffmpeg.so.56', 'libavformat.so.56', 'avformat'}
local libavcodec = load_lib{
  'libavcodec-ffmpeg.so.56', 'libavcodec.so.56', 'avcodec'}
local libavutil = load_lib{
  'libavutil-ffmpeg.so.54', 'libavutil.so.54', 'avutil'}
local libavfilter = load_lib{
  'libavfilter-ffmpeg.so.5', 'libavfilter.so.5', 'avfilter'}

-- Initialize libavformat
libavformat.av_register_all()

-- Initialize libavfilter
libavfilter.avfilter_register_all()

function M.new(path)
  local self = {}

  self.format_context = ffi.new('AVFormatContext*[1]')
  if libavformat.avformat_open_input(self.format_context, path, nil, nil) < 0 then
    error('Failed to open video input for ' .. path)
  end

  -- Release format context when collected by the GC
  ffi.gc(self.format_context, libavformat.avformat_close_input)

  -- Calculate info about the stream
  if libavformat.avformat_find_stream_info(self.format_context[0], nil) < 0 then
    error('Failed to find stream info for ' .. path)
  end

  -- Select video stream
  local decoder = ffi.new('AVCodec*[1]')
  self.video_stream_index = libavformat.av_find_best_stream(
    self.format_context[0], libavformat.AVMEDIA_TYPE_VIDEO, -1, -1, decoder, 0)
  if self.video_stream_index < 0 then
    error('Failed to find video stream for ' .. path)
  end

  self.video_decoder_context = self.format_context[0].streams[self.video_stream_index].codec

  if libavcodec.avcodec_open2(self.video_decoder_context, decoder[0], nil) < 0 then
    error('Failed to open video decoder')
  end

  -- Release decoder context when collected by the GC
  ffi.gc(self.video_decoder_context, libavcodec.avcodec_close)

  -- -- Print format info
  -- libavformat.av_dump_format(self.format_context[0], 0, path, 0)

  setmetatable(self, {__index = Video})
  return self
end

-- Get video duration in seconds
function Video:duration()
  return tonumber(self.format_context[0].duration) / 1000000.0
end

function Video:pixel_format_name()
  return ffi.string(libavutil.av_get_pix_fmt_name(self.video_decoder_context.pix_fmt))
end

function Video:each_frame(video_callback, audio_callback)
  if audio_callback ~= nil then
    error('Audio frames not supported yet')
  end

  local packet = ffi.new('AVPacket[1]')
  libavcodec.av_init_packet(packet)
  ffi.gc(packet, libavformat.av_packet_unref)

  local frame = libavutil.av_frame_alloc()
  if frame == 0 then
    error('Failed to allocate frame')
  end
  ffi.gc(frame, function(ptr)
    libavutil.av_frame_unref(ptr)
    libavutil.av_frame_free(ptr)
  end)

  local dest_data = ffi.new('uint8_t*[4]')
  local dest_linesize = ffi.new('int[4]')
  ffi.gc(dest_data, function(ptr)
    if dest_data[0] ~= nil then
      libavutil.av_freep(ptr)
    end
  end)

  while libavformat.av_read_frame(self.format_context[0], packet) == 0 do
    -- Make sure packet is from video stream
    if packet[0].stream_index == self.video_stream_index then
      -- Reset fields in frame
      libavutil.av_frame_unref(frame)

      local got_frame = ffi.new('int[1]')
      if libavcodec.avcodec_decode_video2(self.video_decoder_context, frame, got_frame, packet) < 0 then
        error('Failed to decode video frame')
      end

      if got_frame[0] ~= 0 then

        local pix_fmt = self.video_decoder_context.pix_fmt

        local image_size = libavutil.av_image_alloc(dest_data, dest_linesize,
          self.video_decoder_context.width, self.video_decoder_context.height,
          pix_fmt, 1)

        if image_size < 0 then
          error('Failed to allocate image buffer')
        end

        libavutil.av_image_copy(dest_data, dest_linesize,
          ffi.cast(ffi.typeof'const uint8_t**', frame.data), frame.linesize,
          pix_fmt,
          self.video_decoder_context.width, self.video_decoder_context.height);

        video_callback(dest_data, dest_linesize)
      end
    end
  end
end

-- Assumes YUV
function Video:image_to_ascii(dest_data, dest_linesize)
  local max_rows = 24
  local max_cols = 80
  local y_spacing = math.floor(self.video_decoder_context.height / max_rows)
  local x_spacing = math.floor(self.video_decoder_context.width / max_cols)
  local ascii = {}

  for y = 0, (self.video_decoder_context.height - 1) do
    if y % y_spacing == 0 then
      for x = 0, (self.video_decoder_context.width - 1) do
        if x % x_spacing == 0 then
          local luma = dest_data[0][y * dest_linesize[0] + x]
          -- local chrom_u = dest_data[1][y * dest_linesize[1] + x]
          -- local chrom_v = dest_data[2][y * dest_linesize[2] + x]
          if luma > 200 then
            table.insert(ascii, '#')
          elseif luma > 150 then
            table.insert(ascii, '+')
          elseif luma > 100 then
            table.insert(ascii, '-')
          elseif luma > 50 then
            table.insert(ascii, '.')
          else
            table.insert(ascii, ' ')
          end
        end
      end
      table.insert(ascii, '\n')
    end
  end

  return table.concat(ascii, '')
end

return M
