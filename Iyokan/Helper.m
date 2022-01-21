//
//  Helper.m
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

#import "Helper.h"

@implementation Helper

AVPacket *packet;
AVFrame *frame;

AVFormatContext *formatContext;
AVCodecParameters *codecParams;
const AVCodec *codec;
AVCodecContext *codecContext;

- (id) init:(NSString *) filePath {
    const char *cFilePath = [filePath cStringUsingEncoding: NSUTF8StringEncoding];

    formatContext = avformat_alloc_context();
    int ret = avformat_open_input(&formatContext, cFilePath, NULL, NULL);
    if (ret < 0) return NULL;

    ret = avformat_find_stream_info(formatContext, NULL);
    if (ret < 0) return NULL;

    av_dump_format(formatContext, 0, cFilePath, 0);
    _sampleRate = -1;

    return self;
}

- (NSDictionary<NSString *, NSString *> *) getMetadata {
    AVDictionary *dict = formatContext->metadata;
    NSMutableDictionary<NSString *, NSString *> *mutableDict = [[NSMutableDictionary alloc] init];

    AVDictionaryEntry *last = NULL;
    while ((last = av_dict_get(dict, "", last, AV_DICT_IGNORE_SUFFIX))) {
        NSString *key = [[NSString alloc] initWithUTF8String: last->key];
        NSString *value = [[NSString alloc] initWithUTF8String: last->value];
        [mutableDict setObject: value forKey: [key lowercaseString]];
    }
    return mutableDict;
}

BOOL codecIsOpen = NO;
int audioStreamIndex = -1;

- (BOOL) openCodec {
    // find the first audio stream
    audioStreamIndex = -1;
    for (int i = 0; i < formatContext->nb_streams; ++i) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamIndex = i;
            codecParams = formatContext->streams[i]->codecpar;
            break;
        }
    }

    if (audioStreamIndex == -1) return NO;

    codec = avcodec_find_decoder(codecParams->codec_id);
    if (!codec) return NO;

    codecContext = avcodec_alloc_context3(codec);
    codecContext->request_sample_fmt = AV_SAMPLE_FMT_S16;
    codecContext->request_channel_layout = 0;

    AVDictionary *dict = NULL;
    int ret = av_dict_set(&dict, "ac", "2", 0);
    if (ret < 0) return NO;

    ret = avcodec_open2(codecContext, NULL, &dict);
    if (ret < 0) return NO;

    _sampleRate = codecParams->sample_rate;

    packet = av_packet_alloc();
    frame = av_frame_alloc();

    codecIsOpen = YES;
    return YES;
    //    // resample to 16bit 44100 PCM
    //    enum AVSampleFormat inFormat = _codecContext->sample_fmt;
    //    enum AVSampleFormat outFormat = AV_SAMPLE_FMT_S16;
    //
    //    int inSampleRate = _codecContext->sample_rate;
    //    int outSampleRate = 44100;
    //
    //    uint64_t inChannelLayout = _codecContext->channel_layout;
    //    uint64_t outChannelLayout = AV_CH_LAYOUT_MONO;
    //
    //    SwrContext *swrContext = swr_alloc();
    //    swr_alloc_set_opts(swrContext, outChannelLayout, outFormat, outSampleRate, inChannelLayout, inFormat, inSampleRate, 0, NULL);
    //    swr_init(swrContext);
    //
    //    int outChannelCount = av_get_channel_layout_nb_channels(outChannelLayout);
}

- (nullable AVFrame *) nextFrame {
    if (!codecIsOpen) return NULL;
    int ret = 0;
    while (av_read_frame(formatContext, packet) >= 0) {
        if (packet->stream_index != audioStreamIndex) continue;
        ret = avcodec_send_packet(codecContext, packet);
        if (ret < 0) return NULL;
        ret = avcodec_receive_frame(codecContext, frame);
        if (ret < 0) return NULL;
        return frame;
    }
    return NULL;
}

- (void) dealloc {
    av_packet_free(&packet);
    av_frame_free(&frame);
    avcodec_free_context(&codecContext);
    avcodec_close(codecContext);
    avformat_free_context(formatContext);
}

@end
