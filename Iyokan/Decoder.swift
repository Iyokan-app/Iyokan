//
//  Helper.m
//  Dimko
//
//  Created by uiryuu on 2021/07/02.
//

import Foundation
import AVFoundation

fileprivate let serializationQueue = DispatchQueue(label: "dimko.serialization.queue")

class Decoder {
    private let helper: Helper

    var buffers: [CMSampleBuffer] = []

    // audio rendering infrustracture
    let renderSynchronizer = AVSampleBufferRenderSynchronizer()
    let audioRenderer = AVSampleBufferAudioRenderer()

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
        } catch let e {
            print(e)
        }
        subscribeToAudioRenderer()
        startPlayback()
    }

    func subscribeToAudioRenderer() {
        renderSynchronizer.addRenderer(audioRenderer)
        audioRenderer.requestMediaDataWhenReady(on: serializationQueue) {
            while self.audioRenderer.isReadyForMoreMediaData {
                if let sampleBuffer = self.nextSampleBuffer() {
                    self.audioRenderer.enqueue(sampleBuffer)
                }
            }
        }
    }

    func startPlayback() {
        serializationQueue.async {
            self.renderSynchronizer.rate = 1
        }
    }

    func nextSampleBuffer() -> CMSampleBuffer? {
        guard !buffers.isEmpty else { return nil }
        return buffers.removeFirst()
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

        var streamDescription = AudioStreamBasicDescription(
            mSampleRate: Float64(sampleRate),
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 4,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 32,
            mReserved: 0)

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

    func checkErr(_ status: OSStatus) throws {
        guard status == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))}
    }
}
