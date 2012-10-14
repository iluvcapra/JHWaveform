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

#import "JHWaveformView.h"

static NSString *JHWaveformViewNeedsRedisplayCtx = @"JHWaveformViewNeedsRedisplayObserverContext";
static NSString *JHWaveformViewAllowsSelectionCtx = @"JHWaveformViewAllowsSelectionCtx";

@implementation JHWaveformView

@synthesize foregroundColor                 = _foregroundColor;
@synthesize lineColor                       = _lineColor;
@synthesize backgroundColor                 = _backgroundColor;
@synthesize selectedColor                   = _selectedColor;
@synthesize selectedBorderColor             = _selectedBorderColor;
@synthesize gridColor                       = _gridColor;

@synthesize lineWidth                       = _lineWidth;
@synthesize selectedSampleRange             = _selectedSampleRange;
@synthesize allowsSelection                 = _allowsSelection;
@synthesize verticalScale                   = _verticalScale;
@synthesize displaysRuler                   = _displaysRuler;
@synthesize displaysGrid                    = _displaysGrid;
@synthesize rulerMajorTicks                 = _rulerMajorTicks;
@synthesize rulerMinorTicks                 = _rulerMinorTicks;
@synthesize gridTicks                       = _gridTicks;

#define RULER_HEIGHT            25
#define RULER_TICK_INSET        3
#define RULER_MINOR_TICK_FACTOR 0.4f

#define MAX_SAMPLE_DATA         2000

-(id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.foregroundColor = [NSColor grayColor];
        self.backgroundColor = [NSColor controlBackgroundColor];
        self.lineColor       = [NSColor textColor];
        self.selectedColor   = [NSColor selectedControlColor];
        self.selectedBorderColor = [self.selectedColor shadowWithLevel:0.5f];
        self.gridColor       = [NSColor gridColor];
        _sampleData = NULL;
        _sampleDataLength = 0;
        _originalSampleDataLength = 0;
        
        self.lineWidth = 1.0f;
        self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
        _dragging = NO;
        _selectionAnchor = 0;
        self.allowsSelection = YES;
        self.verticalScale = 1.0f;
        self.displaysRuler = YES;
        self.displaysGrid = YES;
        
        self.rulerMajorTicks = 100;
        self.rulerMinorTicks = 10;
        self.gridTicks       = self.rulerMajorTicks;
    }
    
    
    [self addObserver:self forKeyPath:@"foregroundColor" options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"lineColor"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"selectedColor"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"selectedBorderColor"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"gridColor"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"lineWidth"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];

    [self addObserver:self forKeyPath:@"selectedSampleRange"
              options:NSKeyValueObservingOptionNew ^ NSKeyValueObservingOptionOld
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"verticalScale"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"displaysRuler"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"displaysGrid"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    
    [self addObserver:self forKeyPath:@"allowsSelection" options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewAllowsSelectionCtx];
    
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)JHWaveformViewNeedsRedisplayCtx ) {
        if ([keyPath isEqualToString:@"selectedSampleRange"]) {
            NSRange oldSelection = [change[NSKeyValueChangeOldKey] rangeValue];
            NSRange newselection = [change[NSKeyValueChangeNewKey] rangeValue];
            
            [self setNeedsDisplayInRect:NSInsetRect([self rectForSampleSelection:oldSelection], -10.f, -10.0f)];
            // we make an inset rect with a negative number, thus a BIGGER rect, to clean up draw artifacts
            
            [self setNeedsDisplayInRect:[self rulerRect]];
            // we awlays redraw the ruler for the selection thumbs
            
            if (newselection.location == NSNotFound) {
                [self setNeedsDisplay:YES];
            } else {
                [self setNeedsDisplayInRect:NSInsetRect([self rectForSampleSelection:newselection], -10.0f,-10.0f)];
            }
        } else {
            [self setNeedsDisplay:YES];
        }
    } else if (context == (__bridge void *)JHWaveformViewAllowsSelectionCtx) {
        self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
    }
}

#pragma mark Handle Events

-(void)mouseDown:(NSEvent *)event {
    NSPoint clickDown = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
        
    NSUInteger loc = [self xPointToSample:clickDown.x];
    
    if (self.allowsSelection) {
        if (([event modifierFlags] & NSShiftKeyMask) && self.selectedSampleRange.location != NSNotFound) {
            
            NSRange currentSelection  = self.selectedSampleRange;
            
            NSUInteger currentSelectionMidpoint = currentSelection.location + currentSelection.length/2;
            if (loc < currentSelection.location) {
                
                _selectionAnchor = currentSelection.location + currentSelection.length;
                self.selectedSampleRange = NSUnionRange(currentSelection, NSMakeRange(loc, 0));
                
            } else if (NSLocationInRange(loc, currentSelection) &&
                       loc < currentSelectionMidpoint) {
                
                _selectionAnchor = currentSelection.location + currentSelection.length;
                self.selectedSampleRange = NSMakeRange(loc, _selectionAnchor - loc);
                
            } else if (NSLocationInRange(loc, currentSelection) &&
                       loc >= currentSelectionMidpoint) {
                
                _selectionAnchor = currentSelection.location;
                self.selectedSampleRange = NSMakeRange(_selectionAnchor, loc - _selectionAnchor);
            } else {
                
                _selectionAnchor = currentSelection.location;
                self.selectedSampleRange = NSUnionRange(currentSelection, NSMakeRange(loc, 0));
            }
            
            
        } else {
            
            _selectionAnchor = loc;
            [self setNeedsDisplay:YES];
            
            self.selectedSampleRange = NSMakeRange(loc, 0);
        }
    }

    
    _dragging = YES;
}

-(void)mouseDragged:(NSEvent *)event {
    NSPoint clickDown = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
    
    // clamp value if the mouse is dragged off the view
    if (clickDown.x < 0.0f) { clickDown.x = 0.0f;}
    if (clickDown.x > self.bounds.size.width) {clickDown.x = self.bounds.size.width;}
    
    NSUInteger loc = [self xPointToSample:clickDown.x];
    
    if (self.allowsSelection) {
        if (loc < _selectionAnchor) {
            self.selectedSampleRange = NSMakeRange(loc, _selectionAnchor - loc);
        } else {
            self.selectedSampleRange = NSMakeRange(_selectionAnchor, loc - _selectionAnchor);
        }
    }
}

-(void)mouseUp:(NSEvent *)event {
    _dragging = NO;
    if (self.selectedSampleRange.length == 0) {
        self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
    }
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

#pragma mark Drawing Methods

-(NSAffineTransform *)sampleTransform {
    NSRect waveformRect = [self waveformRect];
    NSAffineTransform *retXform = [NSAffineTransform transform];
    [retXform translateXBy:0.0f yBy:waveformRect.size.height / 2];
    [retXform scaleXBy:waveformRect.size.width / ((CGFloat)_originalSampleDataLength -1 )
                   yBy:waveformRect.size.height * _verticalScale / 2];
    return retXform;
}

-(CGFloat)sampleToXPoint:(NSUInteger)sampleIdx {
    return [[self sampleTransform] transformPoint:NSMakePoint( sampleIdx , 0.0f)].x;
}

-(NSUInteger)xPointToSample:(CGFloat)xPoint {
    NSAffineTransform *invertedXform = [self sampleTransform];
    [invertedXform invert];
    return [invertedXform transformPoint:NSMakePoint(xPoint, 0.0f)].x;
}

-(NSAffineTransform *)coalescedSampleTransform {
    NSAffineTransform *retXform = [NSAffineTransform transform];
    NSRect waveformRect = [self waveformRect];
    [retXform translateXBy:0.0f yBy:waveformRect.size.height / 2];
    [retXform scaleXBy:waveformRect.size.width / (((CGFloat)_sampleDataLength - 1 /*we're couting rungs, not fenceposts */ ))
                   yBy:waveformRect.size.height * _verticalScale / 2];
    
    return retXform;

}

-(NSRect)rectForSampleSelection:(NSRange)aSelection {
    NSRect retRect = [self waveformRect];
    if (aSelection.location != NSNotFound) {
        retRect.origin.x = [self sampleToXPoint:aSelection.location];
        retRect.size.width = [[self sampleTransform] transformSize:NSMakeSize( aSelection.length , 0.0f)].width;
    } else {
        retRect = NSZeroRect;
    }
    return retRect;
}

-(NSRect)selectionRect {
    return [self rectForSampleSelection:_selectedSampleRange];
}

-(NSRect)waveformRect {
    NSRect retRect = [self bounds];
    retRect.size.height -= [self rulerRect].size.height;
    return retRect;
}

-(NSRect)rulerRect {
    NSRect retRect = [self bounds];
    if (_displaysRuler) {
        retRect.origin.y = retRect.size.height - RULER_HEIGHT;
        retRect.size.height = RULER_HEIGHT;
    } else {
        retRect = NSZeroRect;
    }
    return retRect;
}

- (void)drawBackground:(NSRect)dirtyRect {
    /* fill background */
    [self.backgroundColor set];
    [NSBezierPath fillRect:dirtyRect];
}

- (void)drawSelectionBox {
    /* fill selection */
    
    if (_selectedSampleRange.location != NSNotFound ||
        _selectedSampleRange.length == 0) {
        [self.selectedColor set];
        NSRect selectedRect = [self selectionRect];
        
        [NSBezierPath fillRect:selectedRect];
        
        [self.selectedBorderColor set];
        [NSBezierPath setDefaultLineWidth:2.0];
        [NSBezierPath strokeRect:selectedRect];
    }
}

-(void)drawSelectionThumbs {
    if (_selectedSampleRange.location != NSNotFound) {
        NSBezierPath *thumb = [NSBezierPath bezierPath];
        [thumb moveToPoint:NSMakePoint([self selectionRect].origin.x,
                                       [self rulerRect].origin.y + RULER_TICK_INSET)];
        [thumb lineToPoint:NSMakePoint([self selectionRect].origin.x,
                                       [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        [thumb lineToPoint:NSMakePoint([self selectionRect].origin.x + [self rulerRect].size.height / 2 - RULER_TICK_INSET,
                                       [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        [thumb closePath];
        
        NSBezierPath *endThumb = [NSBezierPath bezierPath];
        [endThumb moveToPoint:NSMakePoint([self selectionRect].origin.x + [self selectionRect].size.width,
                                       [self rulerRect].origin.y + RULER_TICK_INSET)];
        [endThumb lineToPoint:NSMakePoint([self selectionRect].origin.x + [self selectionRect].size.width,
                                       [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        [endThumb lineToPoint:NSMakePoint(([self selectionRect].origin.x + [self selectionRect].size.width) - [self rulerRect].size.height / 2 + RULER_TICK_INSET,
                                       [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
       
        [endThumb closePath];
        
        [self.selectedBorderColor set];
        [thumb fill];
        [endThumb fill];
    }
}

- (void)drawGridlines {
    /* gridlines */
    
    [self.gridColor set];
    [NSBezierPath setDefaultLineWidth:0.5f];
    NSUInteger i, xpt;
    for (i = 0; i < _sampleDataLength; i += _gridTicks) {
        xpt = [self sampleToXPoint:i];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, 0)
                                  toPoint:NSMakePoint(xpt, [self bounds].size.height)];
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
    [waveformPath stroke];
    [self.foregroundColor set];
    [waveformPath fill];
}

- (void)drawRuler {
    /* ruler */

    NSRect rulerRect = [self rulerRect];
    
    
    
    NSGradient *rulerGradient = [[NSGradient alloc] initWithStartingColor:[NSColor controlLightHighlightColor]
                                                              endingColor:[NSColor controlHighlightColor]];
    
    [rulerGradient drawInRect:rulerRect angle:270.0f];
    
    
    
    CGFloat tickHeight = rulerRect.size.height - (RULER_TICK_INSET * 2);
    CGFloat minorTickHeight = tickHeight * RULER_MINOR_TICK_FACTOR;
    NSUInteger i, xpt;
    
    [[NSColor controlDarkShadowColor] set];
    [NSBezierPath setDefaultLineWidth:1.0f];
    for (i = 0; i < _originalSampleDataLength; i += _rulerMajorTicks) {
        xpt = [self sampleToXPoint:i];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_TICK_INSET)
                                  toPoint:NSMakePoint(xpt, rulerRect.origin.y+ tickHeight)];
    }
    for (i = 0; i < _originalSampleDataLength; i += _rulerMinorTicks) {
        if (i % _rulerMajorTicks) {
            xpt = [self sampleToXPoint:i];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_TICK_INSET)
                                      toPoint:NSMakePoint(xpt, rulerRect.origin.y+ minorTickHeight)];
        }
    }
    /* draw border around ruler rect */
    [[NSColor controlDarkShadowColor] set];
    [NSBezierPath setDefaultLineWidth:0.5f];
    [NSBezierPath strokeRect:rulerRect];
    
}

- (void)drawOutline {
    /* outline */
    [NSBezierPath setDefaultLineWidth:1.0f];
    [[NSColor controlDarkShadowColor] set];
    [NSBezierPath strokeRect:[self bounds]];
}

-(void)drawRect:(NSRect)dirtyRect {
    
    [self drawBackground:dirtyRect];

    if (NSIntersectsRect(dirtyRect, [self waveformRect])) {
        [self drawSelectionBox];
        if (_displaysGrid) {
            [self drawGridlines];
        }
        
        [self drawWaveformInRect:dirtyRect];
    }
    
    if (_displaysRuler && NSIntersectsRect(dirtyRect, [self rulerRect])) {
        [self drawRuler];
        [self drawSelectionThumbs];
    }
    
    [self drawOutline];
}

- (void)dealloc {
    
    [self removeObserver:self forKeyPath:@"foregroundColor"];
    [self removeObserver:self forKeyPath:@"backgroundColor"];
    [self removeObserver:self forKeyPath:@"linecColor"];
    [self removeObserver:self forKeyPath:@"selectedColor"];
    [self removeObserver:self forKeyPath:@"selectedBorderColor"];
    [self removeObserver:self forKeyPath:@"gridColor"];
    [self removeObserver:self forKeyPath:@"lineWidth"];
    [self removeObserver:self forKeyPath:@"selecetedSampleRange"];
    [self removeObserver:self forKeyPath:@"verticalScale"];
    [self removeObserver:self forKeyPath:@"displaysRuler"];
    [self removeObserver:self forKeyPath:@"displaysGrid"];
    [self removeObserver:self forKeyPath:@"allowsSelection"];

    free(_sampleData);
}

@end
