//
//  JHWaveformView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHWaveformView.h"

static NSString *JHWaveformViewNeedsRedisplayCtx = @"JHWaveformViewNeedsRedisplayObserverContext";

@implementation JHWaveformView

@synthesize foregroundColor =       _foregroundColor;
@synthesize lineColor =             _lineColor;
@synthesize backgroundColor =       _backgroundColor;
@synthesize selectedColor   =       _selectedColor;
@synthesize lineWidth       =       _lineWidth;
@synthesize selectedSampleRange =   _selectedSampleRange;
@synthesize allowsSelection =       _allowsSelection;
@synthesize verticalScale   =       _verticalScale;
@synthesize displaysRuler   =       _displaysRuler;


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
        self.lineWidth = 1.0f;
        self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
        _dragging = NO;
        _selectionAnchor = 0;
        self.allowsSelection = YES;
        self.verticalScale = 1.0f;
        self.displaysRuler = YES;
    }
    
    [self addObserver:self forKeyPath:@"foregroundColor" options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"lineColor"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"lineWidth"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"selectedSampleRange"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"verticalScale"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"displaysRuler"       options:NSKeyValueObservingOptionNew
              context:(void *)JHWaveformViewNeedsRedisplayCtx];
    
 // [self addObserver:self forKeyPath:@"lineFlatness"       options:NSKeyValueObservingOptionNew context:JHWaveformViewNeedsRedisplayCtx];
    
    return self;
}


-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)JHWaveformViewNeedsRedisplayCtx ) {
        [self setNeedsDisplay:YES];
    }
}

-(void)mouseDown:(NSEvent *)event {
    NSPoint clickDown = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
        
    NSUInteger loc = [self _XpointToSample:clickDown.x];
    
    if (self.allowsSelection && ([event modifierFlags] & NSShiftKeyMask)) {
        
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
        self.selectedSampleRange = NSMakeRange(loc, 0);
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
        retRect.size.height = 25;
    } else {
        retRect = NSZeroRect;
    }
    return retRect;
}

-(void)drawRect:(NSRect)dirtyRect {
    
    /* fill background */
    [self.backgroundColor set];
    [NSBezierPath fillRect:self.bounds];
    
    
    NSRect waveformRect = [self waveformRect];
    
    /* fill selection */
    
    if (_selectedSampleRange.location != NSNotFound) {
        [self.selectedColor set];
        NSRect selectedRect = NSMakeRect([self _sampleToXPoint:_selectedSampleRange.location],
                                         0,
                                         [self _sampleToXPoint:_selectedSampleRange.length],
                                         waveformRect.size.height);
        
        [NSBezierPath fillRect:selectedRect];
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
//    [waveformPath setFlatness:_lineFlatness];
    
    [self.lineColor set];
    [waveformPath stroke];
    [self.foregroundColor set];
    [waveformPath fill];
    
    /* ruler */
    if (_displaysRuler) {
        NSRect rulerRect = [self rulerRect];
        [[NSColor blackColor] set];
        [NSBezierPath strokeLineFromPoint:rulerRect.origin
                                  toPoint:NSMakePoint(rulerRect.origin.x + rulerRect.size.width,
                                                      rulerRect.origin.y)];
        
        NSGradient *rulerGradient = [[NSGradient alloc] initWithStartingColor:[NSColor controlLightHighlightColor]
                                                                  endingColor:[NSColor controlHighlightColor]];
        
        [rulerGradient drawInRect:rulerRect angle:270.0f];
        [[NSColor blackColor] set];
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
