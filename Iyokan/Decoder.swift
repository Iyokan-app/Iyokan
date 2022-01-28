//
//  Helper.m
//  Iyokan
//
//  Created by uiryuu on 2021/07/02.
//

import Foundation
import AVFoundation

class Decoder {
    private let helper: Helper

    var buffers: [CMSampleBuffer] = []

    init(_ filePath: String) {
        self.helper = Helper(filePath)!
    }

    func getMetadata() -> Dictionary<String, String> {
        return helper.getMetadata()
    }

    func decode() {
        helper.openCodec()

        let sampleRate = Int32(helper.sampleRate)
        var presentationTimeStamp = CMTime(value: 0, timescale: sampleRate)

        do {
            while (helper.sendPacket()) {
                while (true) {
                    guard let frame = helper.nextFrame()?.pointee else { break }
                    guard let data = frame.data.0 else { return }
                    let sampleBuffer = try makeSampleBuffer(from: data,
                                                            linesize: Int(frame.linesize.0),
                                                            presentationTimeStamp: presentationTimeStamp,
                                                            samples: frame.nb_samples,
                                                            sampleRate: sampleRate)

                    let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
                    let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
                    presentationTimeStamp = pts + duration

                    buffers.append(sampleBuffer)
                }
            }
        } catch let e {
            print(e)
        }
    }

    func nextSampleBuffer() -> CMSampleBuffer? {
        guard !buffers.isEmpty else { return nil }
        return buffers.removeFirst()
    }

    private func getASBD(from format: AVSampleFormat) -> AudioStreamBasicDescription {
        var desc = AudioStreamBasicDescription()
        desc.mSampleRate = Float64(helper.sampleRate)
        desc.mFormatID = kAudioFormatLinearPCM

        switch format {
        case AV_SAMPLE_FMT_U8, AV_SAMPLE_FMT_U8P:
            desc.mBitsPerChannel = 8
        case AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P:
            desc.mBitsPerChannel = 16
        case AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P, AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_FLTP:
            desc.mBitsPerChannel = 32
        case AV_SAMPLE_FMT_S64, AV_SAMPLE_FMT_S64P, AV_SAMPLE_FMT_DBL, AV_SAMPLE_FMT_DBLP:
            desc.mBitsPerChannel = 64
        default:
            break
        }

        // set flags
        if ([AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_DBL, AV_SAMPLE_FMT_FLTP, AV_SAMPLE_FMT_DBLP].contains(format)) {
            desc.mFormatFlags |= kAudioFormatFlagIsFloat
        }

        if ([AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P, AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P, AV_SAMPLE_FMT_S64, AV_SAMPLE_FMT_S64P].contains(format)) {
            desc.mFormatFlags |= kAudioFormatFlagIsSignedInteger
        }

        if ([AV_SAMPLE_FMT_U8P, AV_SAMPLE_FMT_S16P, AV_SAMPLE_FMT_S32P, AV_SAMPLE_FMT_FLTP, AV_SAMPLE_FMT_DBLP, AV_SAMPLE_FMT_S64P].contains(format)) {
            desc.mFormatFlags |= kAudioFormatFlagIsNonInterleaved
            desc.mChannelsPerFrame = 1
            desc.mBytesPerFrame = desc.mBitsPerChannel / 8
            desc.mFramesPerPacket = desc.mChannelsPerFrame
        } else {
            desc.mChannelsPerFrame = 2
            desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame
            desc.mFramesPerPacket = 1
        }

        desc.mBytesPerPacket = desc.mFramesPerPacket * desc.mBytesPerFrame

        return desc
    }

    func makeSampleBuffer(from data: UnsafeRawPointer, linesize: Int, presentationTimeStamp time: CMTime, samples: Int32, sampleRate: Int32) throws -> CMSampleBuffer {
        // make block buffer first
        var status: OSStatus
        let size = linesize
        var outBlockBuffer: CMBlockBuffer? = nil

        // create block buffer
        status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: size,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: size,
            flags: kCMBlockBufferAssureMemoryNowFlag,
            blockBufferOut: &outBlockBuffer)

        try checkErr(status)
        guard let blockBuffer = outBlockBuffer else { throw NSError(domain: NSOSStatusErrorDomain, code: -1)}

        // fill block buffer with data
        status = CMBlockBufferReplaceDataBytes(
            with: data,
            blockBuffer: blockBuffer,
            offsetIntoDestination: 0,
            dataLength: size)

        try checkErr(status)

        var streamDescription = getASBD(from: helper.format)

        var audioFormatDescription: CMAudioFormatDescription? = nil

        status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &streamDescription,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &audioFormatDescription)

        try checkErr(status)

        var timingInfo = CMSampleTimingInfo(
            duration: CMTimeMake(value: 1, timescale: sampleRate),
            presentationTimeStamp: time,
            decodeTimeStamp: .invalid)

        // make the sample buffer using the block buffer
        var sampleBuffer: CMSampleBuffer? = nil

        status = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            formatDescription: audioFormatDescription,
            sampleCount: CMItemCount(samples),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,      // &timingInfo
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer)

        try checkErr(status)

        return sampleBuffer!
    }

    private func checkErr(_ status: OSStatus) throws {
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))}
    }
}
