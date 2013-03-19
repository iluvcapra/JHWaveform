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
#import "JHSampleDataProvider.h"
#import "JHSampleDataMonoizer.h"

#import <Carbon/Carbon.h>

static NSString *JHAudioPreviewPlayerRateObservingCtx           = @"JHAudioPreviewPlayerRateObservingCtx";
static NSString *JHAudioPreviewPlayerSampleRangeObservingCtx    = @"JHAudioPreviewPlayerSampleRangeObservingCtx";
static NSString *JHAudioPreviewNeedsDisplayObservingCtx         = @"JHAudioPreviewNeedsDisplayObservingCtx";

@implementation JHAudioPreviewView

@synthesize playheadColor = _playheadColor;
@synthesize isReadingOverview = _isReadingOverview;

//- (NSUInteger)_audioSampleAtWaveformSample:(NSUInteger)sample {
//    NSUInteger retVal = 0;
//    if (_sampleDataProvider) {
//         retVal = (sample / (float)_sampleDataLength) *  (_assetDuration * [_sampleDataProvider framesPerSecond]);
//    }
//    return retVal;
//}


-(void)_readSamplesFromTrack:(AVAssetTrack *)track ofAsset:(AVAsset *)asset {
    [self willChangeValueForKey:@"isReadingOverview"];
    _isReadingOverview = YES;
    [self didChangeValueForKey:@"isReadingOverview"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        JHSampleDataMonoizer *sdp = [[JHSampleDataMonoizer alloc] initWithSourceProvider:
                                     [JHSampleDataProvider providerWithAsset:asset track:track]];
        
        [self setSampleDataProvider:sdp];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self willChangeValueForKey:@"isReadingOverview"];
            _isReadingOverview = NO;
            [self didChangeValueForKey:@"isReadingOverview"];
        });
    });

}

-(void)_setPlayheadPosition:(float)seconds {
    float prop = seconds / _assetDuration;
    [self setNeedsDisplayInRect:NSMakeRect([self sampleToXPoint:_playheadPosition] - 10.0f, 0.0f,
                                           20.0f, [self bounds].size.height)];
    _playheadPosition = lrintf(_originalSampleDataLength * prop);
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
        self.playheadColor = [NSColor greenColor];
        //self.gridTicks = 
        [self willChangeValueForKey:@"isReadingOverview"];
        _isReadingOverview = NO;
        [self didChangeValueForKey:@"isReadingOverview"];
        
        [self addObserver:self
               forKeyPath:@"selectedSampleRange"
                  options:NSKeyValueObservingOptionNew
                  context:(__bridge void *)(JHAudioPreviewPlayerSampleRangeObservingCtx)];
        
        [self addObserver:self
               forKeyPath:@"playheadColor"
                  options:NSKeyValueObservingOptionNew
                  context:(__bridge void *)(JHAudioPreviewNeedsDisplayObservingCtx)];
    }
    
    return self;
}

- (void)seekPlayerToXPoint:(CGFloat)xPoint {
    if (_sampleDataProvider) {
        NSUInteger loc = [self xPointToSample:xPoint];
        if (loc != NSNotFound) {
            [_player seekToTime:CMTimeMake(loc, [_sampleDataProvider framesPerSecond])];
        }
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
    } else if (context == (__bridge void *)JHAudioPreviewNeedsDisplayObservingCtx) {
        if ([keyPath isEqualToString:@"playheadColor"]) {
            [self setNeedsDisplay:YES];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(BOOL)isReadingOverview {
    return _isReadingOverview;
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

-(BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    if ([theEvent type] == NSKeyDown &&
        [theEvent keyCode] == kVK_Space) {
        if ([self.player rate] == 0.0f) {
            [self.player play];
        } else {
            self.player.rate = 0.0f;
        }
        return YES;
    } else {
        return NO;
    }
}


#pragma mark Drawing

-(void)mouseDown:(NSEvent *)theEvent {
    NSPoint click = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    [self seekPlayerToXPoint:click.x];
    [super mouseDown:theEvent];
}

-(void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    /* draw playhead */
    if (_playheadPosition > 0) { // don't draw the playhead if we're at the head
        [self.playheadColor set];
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
