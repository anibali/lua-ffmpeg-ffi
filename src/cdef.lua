local ffi = require('ffi')

-- Will not work for avformat version 58+, avutil 56+

ffi.cdef[[
typedef void AVCodec;
typedef void AVInputFormat;
typedef void AVDictionary;
typedef void AVClass;
typedef void AVOutputFormat;
typedef void AVIOContext;
typedef void AVProgram;
typedef void AVChapter;
typedef void AVFormatInternal;
typedef void AVPacketSideData;
typedef void AVBufferRef;
typedef void AVFrameSideData;

enum AVDiscard {
  AVDISCARD_NONE      = -16,
  AVDISCARD_DEFAULT   =   0,
  AVDISCARD_NONREF    =   8,
  AVDISCARD_BIDIR     =  16,
  AVDISCARD_NONINTRA  =  24,
  AVDISCARD_NONKEY    =  32,
  AVDISCARD_ALL       =  48,
};

enum AVPictureType {
  AV_PICTURE_TYPE_NONE = 0,
  AV_PICTURE_TYPE_I,
  AV_PICTURE_TYPE_P,
  AV_PICTURE_TYPE_B,
  AV_PICTURE_TYPE_S,
  AV_PICTURE_TYPE_SI,
  AV_PICTURE_TYPE_SP,
  AV_PICTURE_TYPE_BI
};

enum AVMediaType {
  AVMEDIA_TYPE_UNKNOWN = -1,
  AVMEDIA_TYPE_VIDEO,
  AVMEDIA_TYPE_AUDIO,
  AVMEDIA_TYPE_DATA,
  AVMEDIA_TYPE_SUBTITLE,
  AVMEDIA_TYPE_ATTACHMENT
};

enum AVColorPrimaries {
  AVCOL_PRI_RESERVED0   = 0,
  AVCOL_PRI_BT709       = 1,
  AVCOL_PRI_UNSPECIFIED = 2,
  AVCOL_PRI_RESERVED    = 3,
  AVCOL_PRI_BT470M      = 4,

  AVCOL_PRI_BT470BG     = 5,
  AVCOL_PRI_SMPTE170M   = 6,
  AVCOL_PRI_SMPTE240M   = 7,
  AVCOL_PRI_FILM        = 8,
  AVCOL_PRI_BT2020      = 9,
  AVCOL_PRI_SMPTEST428_1= 10
};

enum AVColorTransferCharacteristic {
  AVCOL_TRC_RESERVED0    = 0,
  AVCOL_TRC_BT709        = 1,
  AVCOL_TRC_UNSPECIFIED  = 2,
  AVCOL_TRC_RESERVED     = 3,
  AVCOL_TRC_GAMMA22      = 4,
  AVCOL_TRC_GAMMA28      = 5,
  AVCOL_TRC_SMPTE170M    = 6,
  AVCOL_TRC_SMPTE240M    = 7,
  AVCOL_TRC_LINEAR       = 8,
  AVCOL_TRC_LOG          = 9,
  AVCOL_TRC_LOG_SQRT     = 10,
  AVCOL_TRC_IEC61966_2_4 = 11,
  AVCOL_TRC_BT1361_ECG   = 12,
  AVCOL_TRC_IEC61966_2_1 = 13,
  AVCOL_TRC_BT2020_10    = 14,
  AVCOL_TRC_BT2020_12    = 15,
  AVCOL_TRC_SMPTEST2084  = 16,
  AVCOL_TRC_SMPTEST428_1 = 17
};

enum AVColorSpace {
  AVCOL_SPC_RGB         = 0,
  AVCOL_SPC_BT709       = 1,
  AVCOL_SPC_UNSPECIFIED = 2,
  AVCOL_SPC_RESERVED    = 3,
  AVCOL_SPC_FCC         = 4,
  AVCOL_SPC_BT470BG     = 5,
  AVCOL_SPC_SMPTE170M   = 6,
  AVCOL_SPC_SMPTE240M   = 7,
  AVCOL_SPC_YCOCG       = 8,
  AVCOL_SPC_BT2020_NCL  = 9,
  AVCOL_SPC_BT2020_CL   = 10,
};

enum AVColorRange {
  AVCOL_RANGE_UNSPECIFIED = 0,
  AVCOL_RANGE_MPEG        = 1,
  AVCOL_RANGE_JPEG        = 2
};

enum AVChromaLocation {
  AVCHROMA_LOC_UNSPECIFIED = 0,
  AVCHROMA_LOC_LEFT        = 1,
  AVCHROMA_LOC_CENTER      = 2,
  AVCHROMA_LOC_TOPLEFT     = 3,
  AVCHROMA_LOC_TOP         = 4,
  AVCHROMA_LOC_BOTTOMLEFT  = 5,
  AVCHROMA_LOC_BOTTOM      = 6
};

enum AVCodecID {
  AV_CODEC_ID_NONE,

  // SNIP
};

enum AVDurationEstimationMethod {
  AVFMT_DURATION_FROM_PTS,
  AVFMT_DURATION_FROM_STREAM,
  AVFMT_DURATION_FROM_BITRATE
};

enum AVPixelFormat {
  AV_PIX_FMT_NONE = -1,
  AV_PIX_FMT_YUV420P,
  AV_PIX_FMT_YUYV422,
  AV_PIX_FMT_RGB24,
  AV_PIX_FMT_BGR24,
  AV_PIX_FMT_YUV422P,
  AV_PIX_FMT_YUV444P,
  AV_PIX_FMT_YUV410P,
  AV_PIX_FMT_YUV411P,
  AV_PIX_FMT_GRAY8,

  // SNIP
};

typedef struct AVRational {
  int num;
  int den;
} AVRational;

typedef struct AVFrac {
  int64_t val, num, den;
} AVFrac;

typedef struct AVPacket {
  AVBufferRef *buf;
  int64_t pts;
  int64_t dts;
  uint8_t *data;
  int size;
  int stream_index;
  int flags;
  AVPacketSideData *side_data;
  int side_data_elems;
  int64_t duration;
  int64_t pos;
  int64_t convergence_duration;
  int64_t __padding_to_stop_random_lua_segfault__;
} AVPacket;

typedef struct AVCodecContext {
  const AVClass *av_class;
  int log_level_offset;
  enum AVMediaType codec_type;
  const struct AVCodec *codec;
  char codec_name[32];
  enum AVCodecID codec_id;
  unsigned int codec_tag;
  unsigned int stream_codec_tag;
  void *priv_data;
  struct AVCodecInternal *internal;
  void *opaque;
  int64_t bit_rate;
  int bit_rate_tolerance;
  int global_quality;
  int compression_level;
  int flags;
  int flags2;
  uint8_t *extradata;
  int extradata_size;
  AVRational time_base;
  int ticks_per_frame;
  int delay;
  int width, height;
  int coded_width, coded_height;
  int gop_size;
  enum AVPixelFormat pix_fmt;

  // SNIP
} AVCodecContext;

typedef struct AVStream {
  int index;
  int id;
  AVCodecContext *codec;
  void *priv_data;
  struct AVFrac pts;
  AVRational time_base;
  int64_t start_time;
  int64_t duration;
  int64_t nb_frames;
  int disposition;
  enum AVDiscard discard;
  AVRational sample_aspect_ratio;
  AVDictionary *metadata;
  AVRational avg_frame_rate;
  AVPacket attached_pic;
  AVPacketSideData *side_data;
  int nb_side_data;
  int event_flags;
} AVStream;

typedef struct AVIOInterruptCB {
  int (*callback)(void*);
  void *opaque;
} AVIOInterruptCB;

typedef int (*av_format_control_message)(struct AVFormatContext *s, int type,
                                         void *data, size_t data_size);

typedef struct AVFormatContext {
  const AVClass *av_class;
  struct AVInputFormat *iformat;
  struct AVOutputFormat *oformat;
  void *priv_data;
  AVIOContext *pb;
  int ctx_flags;
  unsigned int nb_streams;
  AVStream **streams;
  char filename[1024];
  int64_t start_time;
  int64_t duration;
  int64_t bit_rate;
  unsigned int packet_size;
  int max_delay;
  int flags;
  int64_t probesize;
  int64_t max_analyze_duration;
  const uint8_t *key;
  int keylen;
  unsigned int nb_programs;
  AVProgram **programs;
  enum AVCodecID video_codec_id;
  enum AVCodecID audio_codec_id;
  enum AVCodecID subtitle_codec_id;
  unsigned int max_index_size;
  unsigned int max_picture_buffer;
  unsigned int nb_chapters;
  AVChapter **chapters;
  AVDictionary *metadata;
  int64_t start_time_realtime;
  int fps_probe_size;
  int error_recognition;
  AVIOInterruptCB interrupt_callback;
  int debug;
  int64_t max_interleave_delta;
  int strict_std_compliance;
  int event_flags;
  int max_ts_probe;
  int avoid_negative_ts;
  int ts_id;
  int audio_preload;
  int max_chunk_duration;
  int max_chunk_size;
  int use_wallclock_as_timestamps;
  int avio_flags;
  enum AVDurationEstimationMethod duration_estimation_method;
  int64_t skip_initial_bytes;
  unsigned int correct_ts_overflow;
  int seek2any;
  int flush_packets;
  int probe_score;
  int format_probesize;
  char *codec_whitelist;
  char *format_whitelist;
  AVFormatInternal *internal;
  int io_repositioned;
  AVCodec *video_codec;
  AVCodec *audio_codec;
  AVCodec *subtitle_codec;
  AVCodec *data_codec;
  int metadata_header_padding;
  void *opaque;
  av_format_control_message control_message_cb;
  int64_t output_ts_offset;
  uint8_t *dump_separator;
  enum AVCodecID data_codec_id;
  int (*open_cb)(struct AVFormatContext *s, AVIOContext **p, const char *url, int flags, const AVIOInterruptCB *int_cb, AVDictionary **options);
} AVFormatContext;

typedef struct AVFrame {
  uint8_t *data[8];
  int linesize[8];
  uint8_t **extended_data;
  int width, height;
  int nb_samples;
  int format;
  int key_frame;
  enum AVPictureType pict_type;
  AVRational sample_aspect_ratio;
  int64_t pts;
  int64_t pkt_pts;
  int64_t pkt_dts;
  int coded_picture_number;
  int display_picture_number;
  int quality;
  void *opaque;
  uint64_t error[8];
  int repeat_pict;
  int interlaced_frame;
  int top_field_first;
  int palette_has_changed;
  int64_t reordered_opaque;
  int sample_rate;
  uint64_t channel_layout;
  AVBufferRef *buf[8];
  AVBufferRef **extended_buf;
  int        nb_extended_buf;
  AVFrameSideData **side_data;
  int            nb_side_data;
  int flags;
  enum AVColorRange color_range;
  enum AVColorPrimaries color_primaries;
  enum AVColorTransferCharacteristic color_trc;
  enum AVColorSpace colorspace;
  enum AVChromaLocation chroma_location;
  int64_t best_effort_timestamp;
  int64_t pkt_pos;
  int64_t pkt_duration;
  AVDictionary *metadata;
  int decode_error_flags;
  int channels;
  int pkt_size;
} AVFrame;

void av_register_all();
AVFormatContext* avformat_alloc_context();
unsigned avformat_version();
const char* avformat_license();
int avformat_open_input(AVFormatContext **ps, const char *filename,
  AVInputFormat *fmt, AVDictionary **options);
void avformat_close_input(AVFormatContext **s);
int avformat_find_stream_info(AVFormatContext *ic, AVDictionary **options);
int av_find_best_stream(AVFormatContext *ic,
                        enum AVMediaType type,
                        int wanted_stream_nb,
                        int related_stream,
                        AVCodec **decoder_ret,
                        int flags);

int avcodec_open2(AVCodecContext *avctx, const AVCodec *codec, AVDictionary **options);
int avcodec_close(AVCodecContext *avctx);

AVFrame* av_frame_alloc();
void av_frame_unref(AVFrame* frame);
void av_frame_free(AVFrame* frame);

int av_read_frame(AVFormatContext *s, AVPacket *pkt);
void av_packet_unref(AVPacket *pkt);
void av_init_packet(AVPacket *pkt);

int avcodec_decode_video2(AVCodecContext *avctx, AVFrame *picture,
                         int *got_picture_ptr,
                         const AVPacket *avpkt);

void av_dump_format(AVFormatContext *ic,
                    int index,
                    const char *url,
                    int is_output);

int av_image_alloc(uint8_t *pointers[4], int linesizes[4],
                   int w, int h, enum AVPixelFormat pix_fmt, int align);
void av_image_copy(uint8_t *dst_data[4], int dst_linesizes[4],
                   const uint8_t *src_data[4], const int src_linesizes[4],
                   enum AVPixelFormat pix_fmt, int width, int height);

void av_freep(void *ptr);


const char* av_get_pix_fmt_name(enum AVPixelFormat pix_fmt);
]]
