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
        self.backgroundThreshold = 0.2f;
        self.backgroundColor = [NSColor blackColor];
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

-(NSAffineTransform *)sampleTransform {
    NSRect signalRect = [self signalRect];
    NSAffineTransform *retXform = [NSAffineTransform transform];
    [retXform translateXBy:0.0f yBy:0.0f];
    [retXform scaleXBy:signalRect.size.width / ((CGFloat)_originalSampleDataLength -1 )
                   yBy:signalRect.size.height / (CGFloat)_samplesPerFrame ];
    return retXform;
}

-(void)drawSignalInRect:(NSRect)dirtyRect {
    
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:[self signalRect]];
    [[self sampleTransform] concat];
    
    NSUInteger i, j;
    float value = 0.0f;
    for (i = 0; i < _frames; i++) {
        for (j = 0; j < _samplesPerFrame; j++) {
            value = _waterfallData[i * _samplesPerFrame + j];
            if (value > _backgroundThreshold) {
                [[_intensityGradient interpolatedColorAtLocation:value] set];
                [[NSBezierPath bezierPathWithRect:NSMakeRect(i, j, 1.0f, 1.0f)] fill];
            }
        }
    }
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)dealloc {
    [self setData:NULL frames:0 samplesPerFrame:0];
}

@end
