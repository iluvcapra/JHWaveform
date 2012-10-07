//
//  JHAudioPreview.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/4/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

// Copyright (c) 2012, Jamie Hardt
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OR
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "JHAudioPreviewView.h"
#import <CoreMedia/CoreMedia.h>

@implementation JHAudioPreviewView

// 10,000 samples total

#define ASSET_SAMPLE_RATE   ( 48000 )

static NSString *JHAudioPreviewPlayerRateObservingCtx           = @"JHAudioPreviewPlayerRateObservingCtx";
static NSString *JHAudioPreviewPlayerSampleRangeObservingCtx    = @"JHAudioPreviewPlayerSampleRangeObservingCtx";

- (NSUInteger)_audioSampleAtWaveformSample:(NSUInteger)sample {
    
    /* we coalesce each stride into _TWO_ samples, hence the 0.5 */
    return (sample / (float)_sampleDataLength) *  (_assetDuration * (float)ASSET_SAMPLE_RATE);
}

- (NSData *)_assetSamplesFromTrack:(AVAssetTrack *)track
                           ofAsset:(AVAsset *)asset
               asFloatArrayOrError:(NSError **)error {

    AVAssetReader *sampleReader = [[AVAssetReader alloc] initWithAsset:asset
                                                                 error:error];
    NSMutableData *floatData = nil;
    
    if (*error == nil) {
        AVAssetTrack *theTrack = track;
        
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

-(void)_readSamplesFromTrack:(AVAssetTrack *)track ofAsset:(AVAsset *)asset {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *floatData;
        NSError *error;
        floatData = [self _assetSamplesFromTrack:track ofAsset:asset asFloatArrayOrError:&error];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self setWaveform:(float *)[floatData bytes] length:[floatData length] / sizeof(float)];
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
        self.rulerMajorTicks = ASSET_SAMPLE_RATE * 10 / 2000;
        self.rulerMinorTicks = ASSET_SAMPLE_RATE / 2000;
    }
    
    [self addObserver:self
           forKeyPath:@"selectedSampleRange"
              options:NSKeyValueObservingOptionNew
              context:(__bridge void *)(JHAudioPreviewPlayerSampleRangeObservingCtx)];
    
    return self;
}

- (void)seekPlayerToXPoint:(CGFloat)xPoint {
    NSUInteger loc = [self xPointToSample:xPoint];
    if (loc != NSNotFound) {
        [_player seekToTime:CMTimeMake([self _audioSampleAtWaveformSample:loc], ASSET_SAMPLE_RATE)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == (__bridge void *)(JHAudioPreviewPlayerRateObservingCtx)) {
//        if ([change[NSKeyValueChangeNewKey] isEqual:@(0.0f) ]) {
//            [self seekToSelectedSampleLocation];
//        }
//    } else if (context == (__bridge void *)JHAudioPreviewPlayerSampleRangeObservingCtx) {
//        if (_player.rate == 0.0f) {
//            [self seekToSelectedSampleLocation];
//        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(AVPlayer *)player {
    return _player;
}

-(void)setPlayer:(AVPlayer *)player {
    if (player != _player) {
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
                [self _readSamplesFromTrack:audioTracks[0] ofAsset:_player.currentItem.asset];
            }
        }
    }

}

-(void)mouseDown:(NSEvent *)theEvent {
    NSPoint click = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    [self seekPlayerToXPoint:click.x];
    [super mouseDown:theEvent];
}

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
