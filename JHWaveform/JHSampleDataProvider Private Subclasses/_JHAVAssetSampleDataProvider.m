//
//  _JHAVAssetSampleDataProvider.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/21/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "_JHAVAssetSampleDataProvider.h"

@implementation _JHAVAssetSampleDataProvider

-(void)loadDataIfNecessary {
    if (!_loadedData) {
        _loadedData = [self _loadDataWithAsset:_asset
                           track:_track
                     inTimeRange:_timeRange];
    }
}

-(BOOL)_loadDataWithAsset:(AVAsset *)asset
                    track:(AVAssetTrack *)track
              inTimeRange:(CMTimeRange)range {
    
    NSError *error = nil;
    AVAssetReader *sampleReader = [[AVAssetReader alloc] initWithAsset:asset
                                                                 error:&error];
    
    sampleReader.timeRange = range;
    
    NSMutableData *floatData = nil;
    
    if (error == nil) {
        AVAssetTrack *theTrack = track;
        
        NSDictionary *lpcmOutputSetting = @{
        AVFormatIDKey : @( kAudioFormatLinearPCM ),
        AVLinearPCMIsFloatKey : @YES,
        AVLinearPCMBitDepthKey : @32,
        AVLinearPCMIsNonInterleaved : @NO,
        };
        
        
        AVAssetReaderTrackOutput *trackOutput =
        [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack: theTrack
                                                   outputSettings: lpcmOutputSetting];
        [sampleReader addOutput:trackOutput ];
        
        [sampleReader startReading];
        
        CMSampleBufferRef buf;
        floatData = [NSMutableData new];
        BOOL _gotMetadata = NO;
        
        while ((buf = [trackOutput copyNextSampleBuffer])) {
            if (!_gotMetadata) {
                CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(buf);
                const AudioStreamBasicDescription *streamDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc);
                
                _samplesPerFrame = streamDesc->mChannelsPerFrame;
                _framesPerSecond = streamDesc->mSampleRate;
                _gotMetadata = YES;
            }
            
            
            AudioBufferList audioBufferList;
            CMBlockBufferRef blockBuffer;
            
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(buf,
                                                                    NULL,
                                                                    &audioBufferList,
                                                                    sizeof(audioBufferList),
                                                                    NULL,
                                                                    NULL,
                                                                    0,
                                                                    &blockBuffer);
            
            NSUInteger i;
            // we've set AVLinearPCMIsNonInterleaved to be NO (double negative there)
            // so multiple buffers should just be coniguous, right?
            for (i = 0 ; i < audioBufferList.mNumberBuffers; i++) {
                AudioBuffer audioBuffer = audioBufferList.mBuffers[i];
                Float32 *frame = (Float32*)audioBuffer.mData;
                [floatData appendBytes:frame length:audioBuffer.mDataByteSize];
            }
            
            CFRelease(blockBuffer);
            CFRelease(buf);
            blockBuffer = NULL;
            buf = NULL;
        }
        
        [sampleReader cancelReading];
        
        _sampleDataBuffer = [NSData dataWithData:floatData];
        
        return YES;
    } else {
        _sampleDataBuffer = [NSData data];
        return NO;
    }
}

-(id)initWithAsset:(AVAsset *)asset
             track:(AVAssetTrack *)track
         timeRange:(CMTimeRange)range {
    self = [super init];
    if (self) {
        NSAssert(asset, @"asset argument must not be nil");
        NSAssert(track, @"asset argument must not be nil");
        
        _asset = asset;
        _track = track;
        _timeRange = range;
        _loadedData = NO;
        
    }
    return self;
}

-(NSUInteger)framesLength {
    [self loadDataIfNecessary];
    return [super framesLength];
}

-(NSUInteger)samplesPerFrame {
    [self loadDataIfNecessary];
    return [super samplesPerFrame];
}

-(double)framesPerSecond {
    [self loadDataIfNecessary];
    return [super framesPerSecond];
}


@end
