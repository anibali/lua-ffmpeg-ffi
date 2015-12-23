------------
-- Lua bindings to FFmpeg libraries.
-- @module ffmpeg
-- @author Aiden Nibali
-- @license MIT
-- @copyright Aiden Nibali 2015

local ffi = require('ffi')

local M = {}
local Video = {}
local VideoFrame = {}

-- Write includes to a temporary file
local includes_path = os.tmpname()
local includes_file = io.open(includes_path, 'w')
includes_file:write[[
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavfilter/avfiltergraph.h>
#include <libavfilter/avcodec.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/opt.h>
#include <libavutil/imgutils.h>
]]
includes_file:close()

-- Preprocess header files to get C declarations
local cpp_output = io.popen('cpp -P -w -x c ' .. includes_path)
local def = cpp_output:read('*all')
cpp_output:close()
os.remove(includes_path)

-- Parse C declarations with FFI
ffi.cdef(def)

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

M.libavformat = libavformat
M.libavcodec = libavcodec
M.libavutil = libavutil
M.libavfilter = libavfilter

local AV_OPT_SEARCH_CHILDREN = 1

local av_log_level = {
  quiet   = -8,
  panic   = 0,
  fatal   = 8,
  error   = 16,
  warning = 24,
  info    = 32,
  verbose = 40,
  debug   = 48,
  trace   = 56
}

libavutil.av_log_set_level(av_log_level.error)

-- Initialize libavformat
libavformat.av_register_all()

-- Initialize libavfilter
libavfilter.avfilter_register_all()

local function copy_object(original)
  local copy
  if type(original) == 'table' then
    copy = {}
    for k, v in pairs(original) do
      copy[k] = v
    end
    setmetatable(copy, getmetatable(original))
  else
    copy = original
  end
  return copy
end

local function new_video_frame(ffi_frame)
  local self = {ffi_frame = ffi_frame}
  setmetatable(self, {__index = VideoFrame})

  return self
end

local function create_frame_reader(self)
  local frame_reader = coroutine.create(function()
    local packet = ffi.new('AVPacket[1]')
    libavcodec.av_init_packet(packet)
    ffi.gc(packet, libavformat.av_packet_unref)

    local frame = ffi.new('AVFrame*[1]', libavutil.av_frame_alloc())
    if frame[0] == 0 then
      error('Failed to allocate frame')
    end
    ffi.gc(frame, function(ptr)
      libavutil.av_frame_unref(ptr[0])
      libavutil.av_frame_free(ptr)
    end)

    local filtered_frame
    if self.is_filtered then
      filtered_frame = ffi.new('AVFrame*[1]', libavutil.av_frame_alloc())
      if filtered_frame[0] == 0 then
        error('Failed to allocate filtered_frame')
      end
      ffi.gc(filtered_frame, function(ptr)
        libavutil.av_frame_unref(ptr[0])
        libavutil.av_frame_free(ptr)
      end)
    end

    while libavformat.av_read_frame(self.format_context[0], packet) == 0 do
      -- Make sure packet is from video stream
      if packet[0].stream_index == self.video_stream_index then
        -- Reset fields in frame
        libavutil.av_frame_unref(frame[0])

        local got_frame = ffi.new('int[1]')
        if libavcodec.avcodec_decode_video2(self.video_decoder_context, frame[0], got_frame, packet) < 0 then
          error('Failed to decode video frame')
        end

        if got_frame[0] ~= 0 then
          if self.is_filtered then
            -- Push the decoded frame into the filtergraph
            if libavfilter.av_buffersrc_add_frame_flags(self.buffersrc_context[0],
              frame[0], libavfilter.AV_BUFFERSRC_FLAG_KEEP_REF) < 0
            then
              error('Error while feeding the filtergraph')
            end

            -- Pull filtered frames from the filtergraph
            libavutil.av_frame_unref(filtered_frame[0]);
            while libavfilter.av_buffersink_get_frame(self.buffersink_context[0], filtered_frame[0]) >= 0 do
              coroutine.yield(filtered_frame[0], 'video')
            end
          else
            coroutine.yield(frame[0], 'video')
          end
        end

      else
        -- TODO: Audio frames
      end
    end
  end)

  return frame_reader
end

---- Opens a video file for reading.
--
-- @string path A relative or absolute path to the video file.
-- @treturn Video
function M.new(path)
  local self = {is_filtered = false}
  setmetatable(self, {__index = Video})

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

  return self
end

--- A Video class.
-- @type Video

---- Sets a filter to apply to the video.
--
-- @string pixel_format_name The name of the desired output pixel format.
-- Pixel names can be found in
-- [pixdesc.c](https://www.ffmpeg.org/doxygen/1.1/pixdesc_8c_source.html).
-- @string[opt='null'] filterchain The filterchain to be applied. Refer to the
-- [libav documentation](https://libav.org/documentation/libavfilter.html)
-- for the syntax of this string.
-- @treturn Video A copy of this `Video` with the specified filter set
-- up.
--
-- @usage
-- -- Set up a filter which scales the video to 128x128 pixels, flips it
-- -- horizontally and sets the output pixel format to 24-bit RGB:
-- video = video:filter('rgb24', 'scale=128x128,hflip')
function Video:filter(pixel_format_name, filterchain)
  assert(not self.is_filtered)

  local video = copy_object(self)

  filterchain = filterchain or 'null'
  local buffersrc = libavfilter.avfilter_get_by_name('buffer');
  local buffersink = libavfilter.avfilter_get_by_name('buffersink');
  local outputs = ffi.new('AVFilterInOut*[1]', libavfilter.avfilter_inout_alloc());
  ffi.gc(outputs, libavfilter.avfilter_inout_free)
  local inputs = ffi.new('AVFilterInOut*[1]', libavfilter.avfilter_inout_alloc());
  ffi.gc(inputs, libavfilter.avfilter_inout_free)

  local filter_graph = ffi.new('AVFilterGraph*[1]', libavfilter.avfilter_graph_alloc());
  ffi.gc(filter_graph, libavfilter.avfilter_graph_free)

  local args = string.format(
    'video_size=%dx%d:pix_fmt=%d:time_base=%d/%d:pixel_aspect=%d/%d',
    video.video_decoder_context.width,
    video.video_decoder_context.height,
    tonumber(video.video_decoder_context.pix_fmt),
    video.video_decoder_context.time_base.num,
    video.video_decoder_context.time_base.den,
    video.video_decoder_context.sample_aspect_ratio.num,
    video.video_decoder_context.sample_aspect_ratio.den)

  local buffersrc_context = ffi.new('AVFilterContext*[1]');
  if libavfilter.avfilter_graph_create_filter(
    buffersrc_context, buffersrc, 'in', args, nil, filter_graph[0]) < 0
  then
    error('Failed to create buffer source')
  end

  local buffersink_context = ffi.new('AVFilterContext*[1]');
  if libavfilter.avfilter_graph_create_filter(
    buffersink_context, buffersink, 'out', nil, nil, filter_graph[0]) < 0
  then
    error('Failed to create buffer sink')
  end

  local pix_fmt = libavutil.av_get_pix_fmt(pixel_format_name)
  if pix_fmt == libavutil.AV_PIX_FMT_NONE then
    error('Invalid pixel format name: ' .. pixel_format_name)
  end
  local pix_fmts = ffi.new('enum AVPixelFormat[1]', {pix_fmt})
  if libavutil.av_opt_set_bin(buffersink_context[0],
    'pix_fmts', ffi.cast('const unsigned char*', pix_fmts),
    1 * ffi.sizeof('enum AVPixelFormat'), AV_OPT_SEARCH_CHILDREN) < 0
  then
    error('Failed to set output pixel format')
  end

  outputs[0].name       = libavutil.av_strdup('in');
  outputs[0].filter_ctx = buffersrc_context[0];
  outputs[0].pad_idx    = 0;
  outputs[0].next       = nil;
  inputs[0].name        = libavutil.av_strdup('out');
  inputs[0].filter_ctx  = buffersink_context[0];
  inputs[0].pad_idx     = 0;
  inputs[0].next        = nil;

  if libavfilter.avfilter_graph_parse_ptr(filter_graph[0], filterchain,
    inputs, outputs, nil) < 0
  then
    error('avfilter_graph_parse_ptr failed')
  end

  if libavfilter.avfilter_graph_config(filter_graph[0], nil) < 0 then
    error('avfilter_graph_config failed')
  end

  video.filter_graph = filter_graph
  video.buffersrc_context = buffersrc_context
  video.buffersink_context = buffersink_context
  video.is_filtered = true

  return video
end

---- Gets the video duration in seconds.
function Video:duration()
  return tonumber(self.format_context[0].duration) / 1000000.0
end

---- Gets the name of the video pixel format.
function Video:pixel_format_name()
  return ffi.string(libavutil.av_get_pix_fmt_name(self.video_decoder_context.pix_fmt))
end

---- Reads the next video frame.
-- @treturn VideoFrame
function Video:read_video_frame()
  self.frame_reader = self.frame_reader or create_frame_reader(self)

  while true do
    if coroutine.status(self.frame_reader) == 'dead' then
      error('End of stream')
    end

    local ok, frame, frame_type = coroutine.resume(self.frame_reader)

    if not ok then
      error(frame)
    end

    if frame_type == 'video' then
      return new_video_frame(frame)
    end
  end
end

function Video:each_frame(video_callback, audio_callback)
  if audio_callback ~= nil then
    error('Audio frames not supported yet')
  end

  local running = true
  while running do
    local ok, res = pcall(self.read_video_frame, self)
    if ok then
      video_callback(res)
    else
      running = false
    end
  end
end

--- A VideoFrame class.
-- @type VideoFrame

---- Converts the video frame to an ASCII visualisation.
function VideoFrame:to_ascii()
  local frame = self.ffi_frame
  if frame.format ~= libavutil.AV_PIX_FMT_GRAY8 then
    error(string.format(
      'Unexpected pixel format "%s", frame_to_ascii requires "%s"',
      ffi.string(libavutil.av_get_pix_fmt_name(frame.format)),
      ffi.string(libavutil.av_get_pix_fmt_name(libavutil.AV_PIX_FMT_GRAY8))))
  end

  local ascii = {}

  for y = 0, (frame.height - 1) do
    for x = 0, (frame.width - 1) do
      local luma = frame.data[0][y * frame.linesize[0] + x]
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
    table.insert(ascii, '\n')
  end

  return table.concat(ascii, '')
end

M.Video = Video
M.VideoFrame = VideoFrame

return M
