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
        _precalculatedImageRep = nil;
        _sampleDataProvider = nil;
    }
    
    return self;
}

-(void)_precalculateImageRep {
    _precalculatedImageRep = nil;
    if (_frames > 0 && _samplesPerFrame > 0) {
        _precalculatedImageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                                         pixelsWide: _frames
                                                                         pixelsHigh: _samplesPerFrame
                                                                      bitsPerSample: 8
                                                                    samplesPerPixel: 4
                                                                           hasAlpha: YES
                                                                           isPlanar: NO
                                                                     colorSpaceName: NSCalibratedRGBColorSpace
                                                                        bytesPerRow: _frames * 4
                                                                       bitsPerPixel: 32];
        NSUInteger i, j;
        float value = 0.0f;
        for (i = 0; i < [_precalculatedImageRep pixelsWide]; i++) {
            for (j = [_precalculatedImageRep pixelsHigh]; j > 0; --j) {
                value = _waterfallData[i * _samplesPerFrame + j];
                NSColor *theColor;
                if (value > _backgroundThreshold) {
                    
                    theColor = [[_intensityGradient interpolatedColorAtLocation:value]
                                colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
                } else {
                    theColor = [[NSColor clearColor]
                                colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                }
                [_precalculatedImageRep setColor:theColor atX:i y:j];
            }
        }
    }
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
    
    [self _precalculateImageRep];
    
    [self setNeedsDisplay:YES];
}

-(void)setSampleDataProvider:(JHSampleDataProvider *)provider {
    if (provider != _sampleDataProvider) {
        
    }
}

#pragma mark Get and Set

-(float)backgroundThreshold {
    return _backgroundThreshold;
}

-(void)setBackgroundThreshold:(float)backgroundThreshold {
    _backgroundThreshold = backgroundThreshold;
    [self setNeedsDisplayInRect:[self signalRect]];
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
    NSAffineTransform *invert = [self sampleTransform];
    [invert invert];
    
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:[self signalRect]];
    [[self sampleTransform] concat];
    
    [_precalculatedImageRep drawAtPoint:NSMakePoint(0.0f, 0.0f)];
    
    [NSGraphicsContext restoreGraphicsState];
}

- (void)dealloc {
    [self setData:NULL frames:0 samplesPerFrame:0];
}

@end
