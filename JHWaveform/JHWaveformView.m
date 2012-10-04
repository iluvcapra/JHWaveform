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

-(void)mouseDown:(NSEvent *)event {
    NSPoint clickDown = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
        
    NSUInteger loc = [self _XpointToSample:clickDown.x];
    
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
    
    NSUInteger loc = [self _XpointToSample:clickDown.x];
    
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
    
    _sampleDataLength = length + 2;
    
    _sampleData[0] = NSMakePoint(0.0f, 0.0f); /* start with a zero */
    _sampleData[_sampleDataLength - 1] = NSMakePoint(_sampleDataLength, 0.0f); /* end with a zero */
    /* we start and end with a zero to make the path fill properly */
    
    NSUInteger i;
    for (i = 1; i < _sampleDataLength - 1; i++) {
        _sampleData[i] = NSMakePoint(i, samples[i-1]);
    }
    
    [self setSelectedSampleRange:NSMakeRange(NSNotFound, 0)];
    [self setNeedsDisplay:YES];
}

-(NSRect)waveformRect {
    NSRect retRect = [self bounds];
    retRect.size.height -= [self rulerRect].size.height;
    return retRect;
}

-(NSRect)rulerRect {
    NSRect retRect = [self bounds];
    if (_displaysRuler) {
        retRect.origin.y = retRect.size.height - 25;
        retRect.size.height = RULER_HEIGHT;
    } else {
        retRect = NSZeroRect;
    }
    return retRect;
}

-(void)drawRect:(NSRect)dirtyRect {
    
    /* fill background */
    [self.backgroundColor set];
    [NSBezierPath fillRect:dirtyRect];
    
    
    NSRect waveformRect = [self waveformRect];
    
    /* gridlines */
    
    if (_displaysGrid) {
        [self.gridColor set];
        [NSBezierPath setDefaultLineWidth:0.5f];
        NSUInteger i, xpt;
        for (i = 0; i < _sampleDataLength; i += _gridTicks) {
            xpt = [self _sampleToXPoint:i];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, 0)
                                      toPoint:NSMakePoint(xpt, [self bounds].size.height)];
        }
        
    }
    
    /* fill selection */
    
    if (_selectedSampleRange.location != NSNotFound ||
        _selectedSampleRange.length == 0) {
        [self.selectedColor set];
        NSRect selectedRect = NSMakeRect([self _sampleToXPoint:_selectedSampleRange.location],
                                         0,
                                         [self _sampleToXPoint:_selectedSampleRange.length],
                                         waveformRect.size.height);
        
        [NSBezierPath fillRect:selectedRect];
        
        [self.selectedBorderColor set];
        [NSBezierPath setDefaultLineWidth:2.0];
        [NSBezierPath strokeRect:selectedRect];
    }
    
    /* draw waveform outlines */
    
    NSAffineTransform *tx = [NSAffineTransform transform];
    [tx translateXBy:0.0f yBy:waveformRect.size.height / 2];
    [tx scaleXBy:waveformRect.size.width / ((CGFloat)_sampleDataLength)
             yBy:waveformRect.size.height * _verticalScale / 2];

    NSBezierPath *waveformPath = [NSBezierPath bezierPath];
    [waveformPath appendBezierPathWithPoints:_sampleData
                                       count:_sampleDataLength];
    
    [waveformPath transformUsingAffineTransform:tx];
    
    [waveformPath setLineWidth:_lineWidth];

    
    [self.lineColor set];
    [waveformPath stroke];
    [self.foregroundColor set];
    [waveformPath fill];
    
    /* ruler */
    if (_displaysRuler) {
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
            xpt = [self _sampleToXPoint:i];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_TICK_INSET)
                                      toPoint:NSMakePoint(xpt, rulerRect.origin.y+ tickHeight)];
        }
        for (i = 0; i < _sampleDataLength; i += _rulerMinorTicks) {
            if (i % _rulerMajorTicks) {
                xpt = [self _sampleToXPoint:i];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_TICK_INSET)
                                          toPoint:NSMakePoint(xpt, rulerRect.origin.y+ minorTickHeight)];
            }
        }
        /* draw border around ruler rect */
        [[NSColor controlDarkShadowColor] set];
        [NSBezierPath setDefaultLineWidth:0.5f];
        [NSBezierPath strokeRect:rulerRect];
    
    }

    
    /* outline */
    [NSBezierPath setDefaultLineWidth:1.0f];
    [[NSColor controlDarkShadowColor] set];
    [NSBezierPath strokeRect:[self bounds]];
}

- (void)dealloc {
    free(_sampleData);
}

@end
