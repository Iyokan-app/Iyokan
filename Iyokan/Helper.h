//
//  Helper.h
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

#ifndef Helper_h
#define Helper_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libavutil/avutil.h"

@interface Helper: NSObject

@property int sampleRate;
@property int bitDepth;
@property const char * _Nonnull formatName;
@property CMTime duration;
@property enum AVSampleFormat format;

- (id _Nullable) init:(NSString * _Nonnull) filePath;
- (NSDictionary<NSString *, NSString *> * _Nonnull) getMetadata;

- (BOOL) sendPacket;
- (nullable AVFrame *) nextFrame;
- (nullable AVFrame *) nextFrameInternal;

@end

#endif /* Helper_h */
