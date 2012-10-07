//
//  JHWaveformView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaveformView.h"

static NSString *JHWaveformViewNeedsRedisplayCtx = @"JHWaveformViewNeedsRedisplayObserverContext";
static NSString *JHWaveformViewAllowsSelectionCtx = @"JHWaveformViewAllowsSelectionCtx";

@implementation JHWaveformView

@synthesize foregroundColor =       _foregroundColor;
@synthesize lineColor =             _lineColor;
@synthesize backgroundColor =       _backgroundColor;
@synthesize selectedColor   =       _selectedColor;
@synthesize selectedBorderColor = _selectedBorderColor;
@synthesize gridColor       =       _gridColor;

@synthesize lineWidth       =       _lineWidth;
@synthesize selectedSampleRange =   _selectedSampleRange;
@synthesize allowsSelection =       _allowsSelection;
@synthesize verticalScale   =       _verticalScale;
@synthesize displaysRuler   =       _displaysRuler;
@synthesize displaysGrid    =       _displaysGrid;
@synthesize rulerMajorTicks =       _rulerMajorTicks;
@synthesize rulerMinorTicks =       _rulerMinorTicks;
@synthesize gridTicks       =       _gridTicks;

#define RULER_HEIGHT            25
#define RULER_TICK_INSET        3
#define RULER_MINOR_TICK_FACTOR 0.5f

-(CGFloat)sampleToXPoint:(NSUInteger)sampleIdx {
    return (float)sampleIdx / (float)_sampleDataLength * self.bounds.size.width;
}

-(NSUInteger)xPointToSample:(CGFloat)xPoint {
    return lrint(floorf((xPoint / self.bounds.size.width) * _sampleDataLength));
}


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
    
    
    
    [self addObserver:self forKeyPath:@"selectedSampleRange"       options:NSKeyValueObservingOptionNew
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
        [self setNeedsDisplay:YES];
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
            _selectedSampleRange = NSMakeRange(loc, 0);
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

-(void)setWaveform:(float *)samples length:(NSUInteger)length {
    
    if (_sampleData) {
        _sampleData = realloc(_sampleData, (length +2) * sizeof(NSPoint));
    } else {
        _sampleData = calloc((length +2), sizeof(NSPoint));
    }
    
    NSAssert(_sampleData != NULL,
             @"Could not allocate memory for sample buffer");
    
    _sampleDataLength = length;
    
    NSUInteger i;
    for (i = 0; i < _sampleDataLength; i++) {
        _sampleData[i] = NSMakePoint(i, samples[i]);
    }
    
    [self setSelectedSampleRange:NSMakeRange(NSNotFound, 0)];
    [self setNeedsDisplay:YES];
}

#pragma mark Drawing Methods

-(NSRect)rectForSampleSelection:(NSRange)aSelection {
    NSRect retRect = [self waveformRect];
    if (aSelection.location != NSNotFound) {
        retRect.origin.x = [self sampleToXPoint:aSelection.location];
        retRect.size.width = [self sampleToXPoint:aSelection.length];
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
    NSRect waveformRect = [self waveformRect];
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:0.0f yBy:waveformRect.size.height / 2];
    [tx scaleXBy:waveformRect.size.width / (((CGFloat)_sampleDataLength - 1 /*we're couting rungs, not fenceposts */ ))
             yBy:waveformRect.size.height * _verticalScale / 2];
    
    NSBezierPath *waveformPath = [NSBezierPath bezierPath];
    [waveformPath moveToPoint:NSMakePoint(0, 0)];
    [waveformPath appendBezierPathWithPoints:_sampleData
                                       count:_sampleDataLength];
    [waveformPath lineToPoint:NSMakePoint(_sampleDataLength, 0)];
    
    [waveformPath transformUsingAffineTransform:tx];
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
    for (i = 0; i < _sampleDataLength; i += _rulerMajorTicks) {
        xpt = [self sampleToXPoint:i];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_TICK_INSET)
                                  toPoint:NSMakePoint(xpt, rulerRect.origin.y+ tickHeight)];
    }
    for (i = 0; i < _sampleDataLength; i += _rulerMinorTicks) {
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
