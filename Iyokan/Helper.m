//
//  Helper.m
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

#import "Helper.h"

#define MAX_FRAME_BUF 100

@implementation Helper {
    AVPacket *packet;
    AVFrame *frame_buf[MAX_FRAME_BUF];
    int tail, head;

    AVFormatContext *formatContext;
    AVCodecParameters *codecParams;
    const AVCodec *codec;
    AVCodecContext *codecContext;

    BOOL codecIsOpen;
    int audioStreamIndex;
}

- (id) init:(NSString *) filePath {
    const char *cFilePath = [filePath cStringUsingEncoding: NSUTF8StringEncoding];
    codecIsOpen = NO;

    tail = 0;
    head = 0;

    formatContext = avformat_alloc_context();
    int ret = avformat_open_input(&formatContext, cFilePath, NULL, NULL);
    if (ret < 0) return NULL;

    ret = avformat_find_stream_info(formatContext, NULL);
    if (ret < 0) return NULL;

    av_dump_format(formatContext, 0, cFilePath, 0);

    // find the first audio stream
    audioStreamIndex = -1;
    for (int i = 0; i < formatContext->nb_streams; ++i) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamIndex = i;
            codecParams = formatContext->streams[i]->codecpar;
            break;
        }
    }

    if (audioStreamIndex == -1) return NULL;

    codec = avcodec_find_decoder(codecParams->codec_id);
    if (!codec) return NULL;

    codecContext = avcodec_alloc_context3(codec);
    ret = avcodec_parameters_to_context(codecContext, codecParams);
    if (ret < 0) return NULL;

    AVDictionary *dict = NULL;
    ret = av_dict_set(&dict, "ac", "2", 0);
    if (ret < 0) return NULL;

    ret = avcodec_open2(codecContext, NULL, &dict);
    if (ret < 0) return NULL;

    _format = codecContext->sample_fmt;
    _formatName = codec->name;
    _sampleRate = codecParams->sample_rate;
    _bitDepth = codecParams->bits_per_raw_sample ? codecParams->bits_per_raw_sample : codecParams->bits_per_coded_sample;
    _duration.timescale = AV_TIME_BASE;
    _duration.value = formatContext->duration;
    _duration.flags |= kCMTimeFlags_Valid;

    packet = av_packet_alloc();

    codecIsOpen = YES;
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

- (BOOL) sendPacket {
    int ret = 0;
    av_packet_free(&packet);
    packet = av_packet_alloc();
    while (av_read_frame(formatContext, packet) >= 0) {
        if (packet->stream_index != audioStreamIndex) {
            av_packet_free(&packet);
            packet = av_packet_alloc();
            continue;
        }
        ret = avcodec_send_packet(codecContext, packet);
        return ret >= 0;
    }
    return NO;
}

- (nullable AVFrame *) nextFrameInternal {
    if (!codecIsOpen) return NULL;

    if (tail) { // has buf
        if (head != tail) {
            return frame_buf[head++];
        }
        else {
            for (int i = 0; i < tail; ++i)
                av_frame_unref(frame_buf[i]);
            head = 0;
            tail = 0;
        }
    }

    if (![self sendPacket]) {
        [NSException raise: @"End of File" format: @""];
    }

    int ret = 0;
    while (ret >= 0) {
        if (!frame_buf[tail])
            frame_buf[tail] = av_frame_alloc();
        ret = avcodec_receive_frame(codecContext, frame_buf[tail]);
        if (ret < 0) {
            if (!tail)
                return NULL;
            else
                return frame_buf[--tail];
        }
        tail++;
    }
    return NULL;
}

- (nullable AVFrame *) nextFrame {
    AVFrame *frame = NULL;
    do {
        @try {
            frame = [self nextFrameInternal];
        }
        @catch (NSException *exception) {
            return NULL;
        }
    } while (!frame);
    return frame;
}

- (void) dealloc {
    av_packet_free(&packet);
    BOOL empty = false;
    for (int i = 0; i < MAX_FRAME_BUF && !empty; ++i)
        if (frame_buf[i])
            av_frame_free(&frame_buf[i]);
        else
            empty = true;
    avcodec_free_context(&codecContext);
    avcodec_close(codecContext);
    avformat_free_context(formatContext);
}

@end
