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

// 10,000 samples total

#define TIME_SCALE_FACTOR   ( 50 )
#define ASSET_SAMPLE_RATE   ( 48000 )

static NSString *JHAudioPreviewPlayerRateObservingCtx           = @"JHAudioPreviewPlayerRateObservingCtx";
static NSString *JHAudioPreviewPlayerSampleRangeObservingCtx    = @"JHAudioPreviewPlayerSampleRangeObservingCtx";

- (NSUInteger)_audioSampleAtWaveformSample:(NSUInteger)sample {
    
    /* we coalesce each stride into _TWO_ samples, hence the 0.5 */
    return sample * TIME_SCALE_FACTOR * MAX(lrintf(_assetDuration),1) * 0.5;
}

- (NSData *)coalesceData:(NSData *)floatData {
    NSUInteger i,j;
    NSUInteger coalesceStride = TIME_SCALE_FACTOR * MAX(lrintf(_assetDuration),1);
    
    Float32 *samples = (Float32 *)[floatData bytes];
    NSMutableData *coalescedData = [NSMutableData new];
    for (i = 0; i < [floatData length] / sizeof(Float32); i += coalesceStride) {
        float max = 0;
        float min = 0;
        for (j = 0; j < coalesceStride; j++) {
            max = MAX(max, samples[i+j]);
            min = MIN(min, samples[i+j]);
        }
        [coalescedData appendBytes:&max length:sizeof(float)];
        [coalescedData appendBytes:&min length:sizeof(float)];
    }
    return [NSData dataWithData:coalescedData];
}

- (NSData *)_assetSamplesAsFloatArrayOrError:(NSError **)error {

    AVAssetReader *sampleReader = [[AVAssetReader alloc] initWithAsset:_player.currentItem.asset
                                                                 error:error];
    NSMutableData *floatData = nil;
    
    if (*error == nil) {
        NSArray *audioTracks = [_player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
        AVAssetTrack *theTrack = [audioTracks objectAtIndex:0];
        
        NSDictionary *lpcmOutputSetting = @{
        AVFormatIDKey : @( kAudioFormatLinearPCM ),
        AVSampleRateKey : @( ASSET_SAMPLE_RATE ),
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

-(void)_readSamplesFromAsset:(AVAsset *)asset {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *floatData;
        NSError *error;
        floatData = [self _assetSamplesAsFloatArrayOrError:&error];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSData *coalescedData;
            coalescedData = [self coalesceData:floatData];
            
            [self setWaveform:(float *)[coalescedData bytes] length:[coalescedData length] / sizeof(float)];
        });
    });

}

-(void)_setPlayheadPosition:(float)seconds {
    float prop = seconds / _assetDuration;
    [self setNeedsDisplayInRect:NSMakeRect([self sampleToXPoint:_playheadPosition] - 10.0f, 0.0f,
                                           20.0f, [self bounds].size.height)];
    _playheadPosition = lrintf(_sampleDataLength * prop);
    [self setNeedsDisplayInRect:NSMakeRect([self sampleToXPoint:_playheadPosition] - 10.0f, 0.0f,
                                           20.0f, [self bounds].size.height)];
}

-(void)_observePlayer {
    __block JHAudioPreviewView *me = self;
    _timeObserverDescriptor = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30)
                                          queue:dispatch_get_main_queue()
                                     usingBlock:^(CMTime currentTime){
                                         [me _setPlayheadPosition: CMTimeGetSeconds(currentTime)];
                                     }];
    
    [_player addObserver:self
              forKeyPath:@"rate"
                 options:NSKeyValueObservingOptionNew
                 context:(__bridge void *)(JHAudioPreviewPlayerRateObservingCtx)];
}

-(void)_stopObservingPlayer {
    [_player removeTimeObserver:_timeObserverDescriptor];
    [_player removeObserver:self forKeyPath:@"rate"];
    _timeObserverDescriptor = nil;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _player = nil;
        _timeObserverDescriptor = nil;
        _playheadPosition = 0;
        _assetDuration = 0.0;
        self.gridTicks = 100;
        self.rulerMajorTicks = 100;
        self.rulerMinorTicks = 10;
    }
    
    [self addObserver:self
           forKeyPath:@"selectedSampleRange"
              options:NSKeyValueObservingOptionNew
              context:(__bridge void *)(JHAudioPreviewPlayerSampleRangeObservingCtx)];
    
    return self;
}

- (void)seekToSelectedSampleLocation {
    NSUInteger loc = self.selectedSampleRange.location;
    if (loc != NSNotFound) {
        [_player seekToTime:CMTimeMake([self _audioSampleAtWaveformSample:loc], ASSET_SAMPLE_RATE)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == (__bridge void *)(JHAudioPreviewPlayerRateObservingCtx)) {
        if ([change[NSKeyValueChangeNewKey] isEqual:@(0.0f) ]) {
            [self seekToSelectedSampleLocation];
        }
    } else if (context == (__bridge void *)JHAudioPreviewPlayerSampleRangeObservingCtx) {
//        if (_player.rate == 0.0f) {
            [self seekToSelectedSampleLocation];
//        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(AVPlayer *)player {
    return _player;
}

-(void)setPlayer:(AVPlayer *)player {
    if (_player) {
        [self _stopObservingPlayer];
        _player = nil;
    }
    _player = player;
    
    if (_player) {
        NSArray *audioTracks = [_player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] == 0) {
            _player = nil;
         } else {
            _assetDuration = CMTimeGetSeconds(_player.currentItem.duration);
            [self _observePlayer];
            [self _readSamplesFromAsset:_player.currentItem.asset];
        }
    }
}

//-(void)setURL:(NSURL *)url error:(NSError *__autoreleasing *)loadError {
//    
//    [self willChangeValueForKey:@"player"];
//    if (_player) {
//        [self _stopObservingPlayer];
//        _player = nil;
//    }
//    
//    _player = [AVPlayer playerWithURL:url];
//    if (_player) {
//        if (_player.status == AVPlayerStatusFailed) {
//            *loadError = _player.error;
//        } else {
//            NSArray *audioTracks = [_player.currentItem.asset tracksWithMediaType:AVMediaTypeAudio];
//            if ([audioTracks count] == 0) {
//                _player = nil;
//                *loadError = [NSError errorWithDomain:@"JHWaveFromErrorDomain" code:-1 userInfo:@{
//                                       NSURLErrorKey : url,
//                           NSLocalizedDescriptionKey : @"Selected file contains no audio tracks.",
//                NSLocalizedRecoverySuggestionErrorKey: @"Try selecting a different file."}];
//            } else {
//                _assetDuration = CMTimeGetSeconds(_player.currentItem.duration);
//                [self _observePlayer];
//                [self _readSamplesFromAsset:_player.currentItem.asset error:loadError];
//            }
//        }
//    } else {
//        *loadError = [NSError errorWithDomain:@"JHWaveFromErrorDomain" code:-1 userInfo:@{
//                               NSURLErrorKey : url,
//                   NSLocalizedDescriptionKey : @"Failed to create a media player for seleceted media.",
//        NSLocalizedRecoverySuggestionErrorKey: @"Selected file may be currupt."}];
//    }
//    [self didChangeValueForKey:@"player"];
//}

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    /* draw playhead */
    if (_playheadPosition > 0) { // don't draw the playhead if we're at the head
        [[NSColor greenColor] set];
        CGFloat xPos = [self sampleToXPoint:_playheadPosition];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(xPos, 0)
                                  toPoint:NSMakePoint(xPos, self.bounds.size.height)];
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"selectedSampleRange"];
    if (_player) {
        [self _stopObservingPlayer];
        _player = nil;
    }
}

@end
