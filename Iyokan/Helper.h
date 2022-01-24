//
//  Helper.h
//  Iyokan
//
//  Created by uiryuu on 21/1/2022.
//

#ifndef Helper_h
#define Helper_h

#import <Foundation/Foundation.h>

#import "libavcodec/avcodec.h"
#import "libavformat/avformat.h"
#import "libavutil/avutil.h"

@interface Helper: NSObject

@property int sampleRate;
@property enum AVSampleFormat format;

- (id _Nullable) init:(NSString * _Nonnull) filePath;
- (BOOL) openCodec;
- (NSDictionary<NSString *, NSString *> * _Nonnull) getMetadata;

- (BOOL) sendPacket;
- (nullable AVFrame *) nextFrame;

@end

#endif /* Helper_h */
