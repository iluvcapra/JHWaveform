//
//  JHWaveformView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
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

#import "JHMonoWaveformView.h"
#import "JHSampleDataProvider.h"

static NSString *JHWaveformViewNeedsRedisplayCtx = @"JHWaveformViewNeedsRedisplayObserverContext";

@implementation JHMonoWaveformView

@synthesize lineColor                       = _lineColor;
@synthesize gridColor                       = _gridColor;

@synthesize lineWidth                       = _lineWidth;
@synthesize verticalScale                   = _verticalScale;

@synthesize displaysGrid                    = _displaysGrid;
@synthesize gridTicks                       = _gridTicks;


#define MAX_SAMPLE_DATA         2000

-(id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {

       // self.displaysRuler = YES;
        
        self.lineColor       = [NSColor textColor];
        self.gridColor       = [NSColor gridColor];
        _sampleData = NULL;
        _sampleDataLength = 0;
        _originalSampleDataLength = 0;
        _sampleDataProvider = nil;
        self.lineWidth = 1.0f;
        self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
        _dragging = NO;
        _selectionAnchor = 0;
        
        self.verticalScale = 1.0f;
        
        self.displaysGrid = YES;
        
       // self.gridTicks       = self.rulerMajorTicks;
    }
    
    
    
    [self addObserver:self forKeyPath:@"lineColor"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"displaysGrid"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"gridColor"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"lineWidth"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"verticalScale"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)JHWaveformViewNeedsRedisplayCtx ) {
        [self setNeedsDisplay:YES];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)scrollWheel:(NSEvent *)theEvent {
        
    self.verticalScale -= theEvent.deltaY / 100.0f;
    self.verticalScale = MAX(self.verticalScale,0);

    [super scrollWheel:theEvent];
}


#pragma mark Set Data

-(void)coalesceSamples:(const float *)inSamples length:(NSUInteger)inSamplesLength
           intoSamples:(float *)outSamples length:(NSUInteger)inOutSamplesLength {
    NSUInteger i,j;
    float stride = (float)inSamplesLength / ((float)inOutSamplesLength / 2);
        // for each stride samples, gather one max value,and one min value
    for (i = 0; i < (inOutSamplesLength / 2); i++ ) {
        outSamples[2 * i    ] = 0.0f;
        outSamples[2 * i + 1] = 0.0f;
        
        for (j = lrintf((float)i * stride);
             j < lrintf(((float)i+1) * stride) && j < inSamplesLength;
             j++) {
            outSamples[2 * i   ] = MAX(outSamples[2*i],inSamples[j]);
            outSamples[2 * i +1] = MIN(outSamples[2*i+1],inSamples[j]);
        }
    }
}

-(NSUInteger)sampleLength {
    return _originalSampleDataLength;
}

-(void)setWaveform:(const float *)samples length:(NSUInteger)length {
    [self willChangeValueForKey:@"sampleLength"];
    _originalSampleDataLength = length;
    [self didChangeValueForKey:@"sampleLength"];
    _sampleDataLength = MIN(length, MAX_SAMPLE_DATA);
    
    if (_sampleData) {
        _sampleData = realloc(_sampleData, _sampleDataLength * sizeof(NSPoint));
    } else {
        _sampleData = calloc( _sampleDataLength , sizeof(NSPoint));
    }
    
    NSAssert(_sampleData != NULL,
             @"Could not allocate memory for sample buffer");
    
    float *coalescedSamples = NULL;
    BOOL freeCoalescedSamples = NO;
    if (_originalSampleDataLength != _sampleDataLength) {
        coalescedSamples = malloc( sizeof(float) * _sampleDataLength);
        freeCoalescedSamples = YES;
        [self coalesceSamples:samples length:length
                  intoSamples:coalescedSamples length:_sampleDataLength];
        
    } else {
        coalescedSamples = (float *)samples;
    }
    
    NSUInteger i;
    for (i = 0; i < _sampleDataLength; i++) {
        _sampleData[i] = NSMakePoint(i, coalescedSamples[i]);
    }
    
    self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
    [self setNeedsDisplay:YES];
    if (freeCoalescedSamples){free(coalescedSamples);}
}

-(void)setSampleDataProvider:(JHSampleDataProvider *)provider {
    if (provider != _sampleDataProvider) {
        _sampleDataProvider = nil;
        _sampleDataProvider = provider;
        NSRange theRange = NSMakeRange(0, [_sampleDataProvider framesLength]);
        
        [_sampleDataProvider yieldSamplesOnChannel:0 inFrameRange:theRange
                               toBlock:^(float *samples, NSRange outRange) {
                                   [self setWaveform:samples length:outRange.length];
                               }];
    }
}

#pragma mark Drawing Methods

-(NSAffineTransform *)sampleTransform {
    NSRect signalRect = [self signalRect];
    NSAffineTransform *retXform = [NSAffineTransform transform];
    [retXform translateXBy:0.0f yBy:signalRect.size.height / 2];
    [retXform scaleXBy:signalRect.size.width / ((CGFloat)_originalSampleDataLength -1 )
                   yBy:signalRect.size.height * _verticalScale / 2];
    return retXform;
}

-(NSAffineTransform *)coalescedSampleTransform {
    NSAffineTransform *retXform = [NSAffineTransform transform];
    NSRect waveformRect = [self signalRect];
    [retXform translateXBy:0.0f yBy:waveformRect.size.height / 2];
    [retXform scaleXBy:waveformRect.size.width / (((CGFloat)_sampleDataLength - 1 /*we're couting rungs, not fenceposts */ ))
                   yBy:waveformRect.size.height * _verticalScale / 2];
    
    return retXform;

}


- (void)drawGridlines {
    /* gridlines */
    
    if (_gridTicks > 0) {
        [self.gridColor set];
        [NSBezierPath setDefaultLineWidth:0.5f];
        NSUInteger i, xpt;
        for (i = 0; i < _sampleDataLength; i += _gridTicks) {
            xpt = [self sampleToXPoint:i];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, 0)
                                      toPoint:NSMakePoint(xpt, [self bounds].size.height)];
        }
    }
}

- (void)drawWaveformInRect:(NSRect)dirtyRect {
    /* draw waveform */
   // NSRect waveformRect = [self waveformRect];
    
    NSBezierPath *waveformPath = [NSBezierPath bezierPath];
    [waveformPath moveToPoint:NSMakePoint(0, 0)];
    [waveformPath appendBezierPathWithPoints:_sampleData
                                       count:_sampleDataLength];
    [waveformPath lineToPoint:NSMakePoint(_sampleDataLength, 0)];
    
    [waveformPath transformUsingAffineTransform:[self coalescedSampleTransform]];
    [waveformPath setLineWidth:_lineWidth];
    
    
    [self.lineColor set];
    [waveformPath stroke]; //aal_add_coverage_span crashes here sometimes
    [self.foregroundColor set];
    [waveformPath fill];
}

-(void)drawSignalInRect:(NSRect)dirtyRect {
    
    if (_displaysGrid) {
        [self drawGridlines];
    }
    
    [self drawWaveformInRect:dirtyRect];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"lineColor"];
    [self removeObserver:self forKeyPath:@"displaysGrid"];
    [self removeObserver:self forKeyPath:@"gridColor"];
    [self removeObserver:self forKeyPath:@"lineWidth"];
    [self removeObserver:self forKeyPath:@"verticalScale"];


    free(_sampleData);
}

@end
