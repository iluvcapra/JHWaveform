//
//  JHWaterfallView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaterfallView.h"

@implementation JHWaterfallView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setData:NULL frames:0 samplesPerFrame:0];
        self.intensityGradient = [[NSGradient alloc] initWithColors:
                                  @[[NSColor blackColor],
                                  [NSColor blueColor],
                                  [NSColor redColor],
                                  [NSColor yellowColor]] ];
    }
    
    return self;
}

-(void)setData:(float *)data
        frames:(NSUInteger)frameCount samplesPerFrame:(NSUInteger)samplesPerFrame {
    NSAssert(
             (data != NULL && frameCount * samplesPerFrame > 0)
             ||
             (data == NULL && frameCount * samplesPerFrame == 0)
             ,@"invalid length (%lu) for data argument (%p)", samplesPerFrame * frameCount, data);
    
    
    if (_waterfallData) {
        free(_waterfallData);
    }
    _samplesPerFrame = samplesPerFrame;
    _originalSampleDataLength = _frames = frameCount;
    
    if (data && _samplesPerFrame * _frames > 0) {
        _waterfallData = calloc(frameCount * samplesPerFrame, sizeof(float));
        memcpy(_waterfallData, data, frameCount * samplesPerFrame * sizeof(float));
    } else {
        _waterfallData = NULL;
    }
    [self setNeedsDisplay:YES];
}

#pragma mark Get and Set

-(float)backgroundThreshold {
    return _backgroundThreshold;
}

-(void)setBackgroundThreshold:(float)backgroundThreshold {
    _backgroundThreshold = backgroundThreshold;
    [self setNeedsDisplay:YES];
}

-(NSGradient *)intensityGradient {
    return _intensityGradient;
}

-(void)setIntensityGradient:(NSGradient *)intensityGradient {
    _intensityGradient = [intensityGradient copy];
    [self setNeedsDisplayInRect:[self signalRect]];
}

#pragma mark Drawing

-(void)drawSignalInRect:(NSRect)dirtyRect {
    
}

- (void)dealloc {
    [self setData:NULL frames:0 samplesPerFrame:0];
}

@end
