//
//  Helper.m
//  Iyokan
//
//  Created by uiryuu on 2021/07/02.
//

import Foundation
import AVFoundation
import os

fileprivate let logger = Logger.init(subsystem: "Iyokan", category: "Decoder")

extension AudioStreamBasicDescription {
    func getSizePerSample() -> Int {
        let bytesPerChannel = Int(mBitsPerChannel >> 3)
        if (mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0 {
            return bytesPerChannel
        } else {
            return bytesPerChannel << 1
        }
    }
}

class BufferProvider {
    private let helper: Helper

    private var presentationTimeStamp: CMTime
    private lazy var asbd: AudioStreamBasicDescription = getASBD(from: helper.format)
    let sampleRate: Int32

    init(_ filePath: String) {
        self.helper = Helper(filePath)!
        self.sampleRate = helper.sampleRate
        self.presentationTimeStamp = CMTime(value: 0, timescale: sampleRate)
    }

    func nextSampleBuffer() -> CMSampleBuffer? {
        guard let frame = helper.nextFrame()?.pointee else { return nil }
        guard let data = frame.data.0 else { return nil }
        let sampleBuffer: CMSampleBuffer
        do {
            sampleBuffer = try makeSampleBuffer(from: data,
                                                // linesize: Int(frame.linesize.0),
                                                presentationTimeStamp: presentationTimeStamp,
                                                samples: frame.nb_samples,
                                                sampleRate: sampleRate)

            let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
            presentationTimeStamp = pts + duration
        } catch {
            logger.fault("Error when making sample buffer")
            return nil
        }
        return sampleBuffer
    }

    private func getASBD(from format: AVSampleFormat) -> AudioStreamBasicDescription {
        var desc = AudioStreamBasicDescription()
        desc.mSampleRate = Float64(sampleRate)
        desc.mFormatID = kAudioFormatLinearPCM

        let bytesPerChannel = UInt32(av_get_bytes_per_sample(format))
        desc.mBitsPerChannel = bytesPerChannel << 3

        // set flags
        if ([AV_SAMPLE_FMT_FLT, AV_SAMPLE_FMT_DBL, AV_SAMPLE_FMT_FLTP, AV_SAMPLE_FMT_DBLP].contains(format)) {
            desc.mFormatFlags |= kAudioFormatFlagIsFloat
        }

        if ([AV_SAMPLE_FMT_S16, AV_SAMPLE_FMT_S16P, AV_SAMPLE_FMT_S32, AV_SAMPLE_FMT_S32P, AV_SAMPLE_FMT_S64, AV_SAMPLE_FMT_S64P].contains(format)) {
            desc.mFormatFlags |= kAudioFormatFlagIsSignedInteger
        }

        if av_sample_fmt_is_planar(format) == 1 {
            desc.mFormatFlags |= kAudioFormatFlagIsNonInterleaved
            desc.mChannelsPerFrame = 1
            desc.mBytesPerFrame = bytesPerChannel
        } else {
            desc.mChannelsPerFrame = 2
            desc.mBytesPerFrame = bytesPerChannel * desc.mChannelsPerFrame
        }

        desc.mFramesPerPacket = 1
        desc.mBytesPerPacket = desc.mFramesPerPacket * desc.mBytesPerFrame

        return desc
    }

    func makeSampleBuffer(from data: UnsafeRawPointer, presentationTimeStamp time: CMTime, samples: Int32, sampleRate: Int32) throws -> CMSampleBuffer {
        // make block buffer first
        var status: OSStatus
        let size = asbd.getSizePerSample() * Int(samples)
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

        var streamDescription = asbd

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
            sampleTimingArray: &timingInfo,
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
