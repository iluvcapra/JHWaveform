//
//  JHAudioPreview.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/4/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHAudioPreview.h"
#import <CoreMedia/CoreMedia.h>

@implementation JHAudioPreview

@synthesize player = _player;

// 10,000 samples total

#define TIME_SCALE_FACTOR   ( 50 )


- (NSData *)_coalesceData:(NSData *)floatData {
    NSUInteger i,j;
    Float64 secondsDuration = CMTimeGetSeconds(_player.currentItem.duration);
    NSUInteger coalesceStride = lrintf(TIME_SCALE_FACTOR * secondsDuration);
    
    Float32 *samples = (Float32 *)[floatData bytes];
    NSMutableData *coalescedData = [NSMutableData new];
    for (i = 0; i < [floatData length] / sizeof(Float32); i += coalesceStride) {
        float *max = malloc(sizeof(float));
        float *min = malloc(sizeof(float));
        for (j = 0; j < coalesceStride; j++) {
            *max = MAX(*max, samples[i+j]);
            *min = MIN(*min, samples[i+j]);
        }
        [coalescedData appendBytes:max length:sizeof(float)];
        [coalescedData appendBytes:min length:sizeof(float)];
        free(max);
        free(min);
    }
    return [NSData dataWithData:coalescedData];
}

- (NSMutableData *)_assetSamplesAsFloatArray {
    NSError *error = nil;
    AVAssetReader *sampleReader = [[AVAssetReader alloc] initWithAsset:_player.currentItem.asset
                                                                 error:&error];
    NSAssert(error == nil, @"could not initialize asset reader: %@", error);
    
    NSArray *audioTracks = [_player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
    AVAssetTrack *theTrack = [audioTracks objectAtIndex:0];
    
    NSDictionary *lpcmOutputSetting = @{
    AVFormatIDKey : @( kAudioFormatLinearPCM ),
    AVSampleRateKey : @48000,
    AVLinearPCMIsFloatKey : @YES,
    AVLinearPCMBitDepthKey : @32,
    AVLinearPCMIsNonInterleaved : @NO,
    AVNumberOfChannelsKey : @1
    };
    
    
    AVAssetReaderTrackOutput *trackOutput =
    [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack: theTrack
                                               outputSettings: lpcmOutputSetting];
    [sampleReader addOutput:trackOutput ];
    
    [sampleReader startReading];
    
    CMSampleBufferRef buf;
    NSMutableData *floatData = [NSMutableData new];
    while ((buf = [trackOutput copyNextSampleBuffer])) {
        
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
        
        AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
        Float32 *frame = (Float32*)audioBuffer.mData;
        [floatData appendBytes:frame length:audioBuffer.mDataByteSize];
        
        CFRelease(blockBuffer);
        CFRelease(buf);
        blockBuffer = NULL;
        buf = NULL;
    }
    
    [sampleReader cancelReading];
    return floatData;
}

-(void)_readSamplesFromAsset:(AVAsset *)asset {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *floatData;
        floatData = [self _assetSamplesAsFloatArray];
        
        NSData *coalescedData;
        coalescedData = [self _coalesceData:floatData];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setWaveform:(float *)[coalescedData bytes] length:[coalescedData length] / sizeof(float)];
        });
    });

}

-(void)_observePlayer {
    _timeObserverDescriptor = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10)
                                          queue:dispatch_get_current_queue()
                                     usingBlock:^(CMTime currentTime){
                                         
                                     }];
}

-(void)_stopObservingPlayer {
    [_player removeTimeObserver:_timeObserverDescriptor];
    _timeObserverDescriptor = nil;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _player = nil;
        _timeObserverDescriptor = nil;
        self.gridTicks = 100;
        self.rulerMajorTicks = 100;
        self.rulerMinorTicks = 10;
    }
    return self;
}

-(void)setURL:(NSURL *)url {
    _player = [AVPlayer playerWithURL:url];
    if (_player != nil) {
        NSArray *audioTracks = [_player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] == 0) {
            _player = nil;
        } else {
            [self _observePlayer];
        }
    } else {
        [self _stopObservingPlayer];
    }
    [self _readSamplesFromAsset:_player.currentItem.asset];
}

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    /* draw playhead */
    
}

- (void)dealloc
{
    if (_timeObserverDescriptor) {
        [self _stopObservingPlayer];
        _player = nil;
    }
}

@end
