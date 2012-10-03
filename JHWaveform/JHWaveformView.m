//
//  JHWaveformView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaveformView.h"

@implementation JHWaveformView

@synthesize foregroundColor =   _foregroundColor;
@synthesize lineColor =         _lineColor;
@synthesize backgroundColor =   _backgroundColor;


-(id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.foregroundColor = [NSColor redColor];
        self.backgroundColor = [NSColor blackColor];
        self.lineColor       = [NSColor whiteColor];
        _sampleData = NULL;
        _sampleDataLength = 0;
    }
    
    return self;
}

-(void)setWaveform:(float *)samples length:(NSUInteger)length {
    
    if (_sampleData) {
        _sampleData = realloc(_sampleData, length * sizeof(NSPoint));
    } else {
        _sampleData = calloc(length, sizeof(NSPoint));
    }
    
    NSAssert(_sampleData != NULL,
             @"Could not allocate memory for sample buffer");
    
    NSUInteger i;
    for (i = 0; i < length; i++) {
        _sampleData[i] = NSMakePoint(i, samples[i]);
    }
    _sampleDataLength = length;
    
    [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect {
    
    /* fill background */
    [self.backgroundColor set];
    [NSBezierPath fillRect:self.bounds];
    
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:0.0f yBy:self.bounds.size.height / 2];
    [tx scaleXBy:self.bounds.size.width / (CGFloat)_sampleDataLength
             yBy:self.bounds.size.height / 2];

    NSBezierPath *waveformPath = [NSBezierPath bezierPath];
    [waveformPath appendBezierPathWithPoints:_sampleData count:_sampleDataLength];
    [waveformPath transformUsingAffineTransform:tx];
    
    [self.lineColor set];
    [waveformPath stroke];
    [self.foregroundColor set];
    [waveformPath fill];
}

- (void)dealloc {
    free(_sampleData);
}

@end
