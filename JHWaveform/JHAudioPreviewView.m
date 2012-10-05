//
//  JHAudioPreview.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/4/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHAudioPreviewView.h"
#import <CoreMedia/CoreMedia.h>

@implementation JHAudioPreviewView

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
        *max = 0;
        *min = 0;
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

- (NSMutableData *)_assetSamplesAsFloatArrayOrError:(NSError **)error {

    AVAssetReader *sampleReader = [[AVAssetReader alloc] initWithAsset:_player.currentItem.asset
                                                                 error:error];
    NSMutableData *floatData = nil;
    
    if (*error == nil) {
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
        floatData = [NSMutableData new];
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
    }
    

    return floatData;
}

-(void)_readSamplesFromAsset:(AVAsset *)asset error:(NSError **)error {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *floatData;
        floatData = [self _assetSamplesAsFloatArrayOrError:error];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSData *coalescedData;
            coalescedData = [self _coalesceData:floatData];
            
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

-(void)setURL:(NSURL *)url error:(NSError *__autoreleasing *)loadError {
    if (_player) {
        [self _stopObservingPlayer];
        _player = nil;
    }
    
    _player = [AVPlayer playerWithURL:url];
    if (_player) {
        if (_player.status == AVPlayerStatusFailed) {
            *loadError = _player.error;
        } else {
            NSArray *audioTracks = [_player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
            if ([audioTracks count] == 0) {
                _player = nil;
                *loadError = [NSError errorWithDomain:@"JHWaveFromErrorDomain" code:-1 userInfo:@{
                                       NSURLErrorKey : url,
                    NSLocalizedDescriptionKey : @"Selected media asset contains no audio tracks.",
                NSLocalizedRecoverySuggestionErrorKey: @"Try selecting a different file."}];
            } else {
                [self _observePlayer];
                [self _readSamplesFromAsset:_player.currentItem.asset error:loadError];
            }
        }
    } else {
        *loadError = [NSError errorWithDomain:@"JHWaveFromErrorDomain" code:-1 userInfo:@{
                               NSURLErrorKey : url,
            NSLocalizedDescriptionKey : @"Failed to create a media player for seleceted media.",
                      NSLocalizedRecoverySuggestionErrorKey: @"Selected file may be currupt."}];
    }
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
