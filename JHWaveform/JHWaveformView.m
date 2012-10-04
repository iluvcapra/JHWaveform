//
//  JHWaveformView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaveformView.h"

@implementation JHWaveformView

@synthesize foregroundColor =       _foregroundColor;
@synthesize lineColor =             _lineColor;
@synthesize backgroundColor =       _backgroundColor;
@synthesize selectedColor   =       _selectedColor;
@synthesize lineWidth       =       _lineWidth;
@synthesize selectedSampleRange =   _selectedSampleRange;

-(CGFloat)_sampleToXPoint:(NSUInteger)sampleIdx {
    return (float)sampleIdx / (float)_sampleDataLength * self.bounds.size.width;
}

-(NSUInteger)_XpointToSample:(CGFloat)xPoint {
    return lrint((xPoint / self.bounds.size.width) * _sampleDataLength);
}

-(id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.foregroundColor = [NSColor grayColor];
        self.backgroundColor = [NSColor controlBackgroundColor];
        self.lineColor       = [NSColor blackColor];
        self.selectedColor   = [NSColor selectedControlColor];
        _sampleData = NULL;
        _sampleDataLength = 0;
        _lineWidth = 1.0f;
        _selectedSampleRange = NSMakeRange(NSNotFound, 0);
        _dragging = NO;
        _selectionOrigin = 0;
    }
    
    [self addObserver:self forKeyPath:@"foregroundColor" options:NSKeyValueObservingOptionNew context:(void *)999];
    [self addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:(void *)999];
    [self addObserver:self forKeyPath:@"lineColor"       options:NSKeyValueObservingOptionNew context:(void *)999];
    [self addObserver:self forKeyPath:@"lineWidth"       options:NSKeyValueObservingOptionNew context:(void *)999];
    [self addObserver:self forKeyPath:@"selectedSampleRange"       options:NSKeyValueObservingOptionNew context:(void *)999];
 // [self addObserver:self forKeyPath:@"lineFlatness"       options:NSKeyValueObservingOptionNew context:(void *)999];
    
    return self;
}


-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if (context == (void *)999) {
        [self setNeedsDisplay:YES];
    }
}

-(void)mouseDown:(NSEvent *)event {
    NSPoint clickDown = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
    
    NSUInteger loc = [self _XpointToSample:clickDown.x];
    
    _selectionOrigin = loc;
    _dragging = YES;
}

-(void)mouseDragged:(NSEvent *)event {
    NSPoint clickDown = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
    
    NSUInteger loc = [self _XpointToSample:clickDown.x];

    if (loc < _selectionOrigin) {
        self.selectedSampleRange = NSMakeRange(loc, _selectionOrigin - loc);
    } else {
        self.selectedSampleRange = NSMakeRange(_selectionOrigin, loc - _selectionOrigin);
    }
    
    
    NSRange extend = NSMakeRange(loc, 1);
    self.selectedSampleRange = NSUnionRange(self.selectedSampleRange, extend);
    
}

-(void)mouseUp:(NSEvent *)event {
    _dragging = NO;
}


-(void)setWaveform:(float *)samples length:(NSUInteger)length {
    
    if (_sampleData) {
        _sampleData = realloc(_sampleData, (length +2) * sizeof(NSPoint));
    } else {
        _sampleData = calloc((length +2), sizeof(NSPoint));
    }
    
    NSAssert(_sampleData != NULL,
             @"Could not allocate memory for sample buffer");
    
    _sampleDataLength = length + 2;
    
    _sampleData[0] = NSMakePoint(0.0f, 0.0f); /* start with a zero */
    _sampleData[_sampleDataLength - 1] = NSMakePoint(_sampleDataLength, 0.0f); /* end with a zero */
    /* we start and end with a zero to make the path fill properly */
    
    NSUInteger i;
    for (i = 1; i < _sampleDataLength - 1; i++) {
        _sampleData[i] = NSMakePoint(i, samples[i-1]);
    }
    
    [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect {
    
    /* fill background */
    [self.backgroundColor set];
    [NSBezierPath fillRect:self.bounds];
    
    
    /* fill selection */
    
    if (_selectedSampleRange.location != NSNotFound) {
        [self.selectedColor set];
        NSRect selectedRect = NSMakeRect([self _sampleToXPoint:_selectedSampleRange.location],
                                         0,
                                         [self _sampleToXPoint:_selectedSampleRange.length],
                                         self.bounds.size.height);
        
        [NSBezierPath fillRect:selectedRect];
    }
    
    /* draw waveform outlines */
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:0.0f yBy:self.bounds.size.height / 2];
    [tx scaleXBy:self.bounds.size.width / ((CGFloat)_sampleDataLength)
             yBy:self.bounds.size.height / 2];

    NSBezierPath *waveformPath = [NSBezierPath bezierPath];
    [waveformPath appendBezierPathWithPoints:_sampleData
                                       count:_sampleDataLength];
    
    [waveformPath transformUsingAffineTransform:tx];
    
    [waveformPath setLineWidth:_lineWidth];
//    [waveformPath setFlatness:_lineFlatness];
    
    [self.lineColor set];
    [waveformPath stroke];
    [self.foregroundColor set];
    [waveformPath fill];
}

- (void)dealloc {
    free(_sampleData);
}

@end
