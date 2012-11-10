//
//  JHSignalView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSignalView.h"

#define RULER_HEIGHT            25
#define RULER_INSET             3
#define RULER_MINOR_TICK_FACTOR 0.4f

static NSString *JHSignalViewNeedsRedisplayCtx = @"JHSignalViewNeedsRedisplayObserverContext";
static NSString *JHSignalViewAllowsSelectionCtx = @"JHSignalViewAllowsSelectionObserverContext";

@implementation JHSignalView

@synthesize foregroundColor                 = _foregroundColor;
@synthesize backgroundColor                 = _backgroundColor;
@synthesize selectedColor                   = _selectedColor;
@synthesize selectedBorderColor             = _selectedBorderColor;

@synthesize selectedSampleRange             = _selectedSampleRange;
@synthesize allowsSelection                 = _allowsSelection;

@synthesize rulerMajorTicks                 = _rulerMajorTicks;
@synthesize rulerMinorTicks                 = _rulerMinorTicks;
@synthesize displaysRuler                   = _displaysRuler;



-(id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.foregroundColor = [NSColor grayColor];
        self.backgroundColor = [NSColor controlBackgroundColor];
        self.selectedColor   = [NSColor selectedControlColor];
        self.selectedBorderColor = [self.selectedColor shadowWithLevel:0.5f];
        self.rulerMajorTicks = 100;
        self.rulerMinorTicks = 10;
        self.allowsSelection = YES;
    }
    
    [self addObserver:self forKeyPath:@"foregroundColor"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHSignalViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"backgroundColor"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHSignalViewNeedsRedisplayCtx];
    
    [self addObserver:self forKeyPath:@"selectedColor"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHSignalViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"selectedBorderColor"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHSignalViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"selectedSampleRange"
              options:NSKeyValueObservingOptionNew ^ NSKeyValueObservingOptionOld
              context:(void *)JHSignalViewNeedsRedisplayCtx];
    
    [self addObserver:self forKeyPath:@"displaysRuler"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHSignalViewNeedsRedisplayCtx];
    [self addObserver:self forKeyPath:@"allowsSelection"
              options:NSKeyValueObservingOptionNew
              context:(void *)JHSignalViewAllowsSelectionCtx];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)(JHSignalViewNeedsRedisplayCtx)) {
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
    } else if (context == (__bridge void *)JHSignalViewAllowsSelectionCtx) {
        self.selectedSampleRange = NSMakeRange(NSNotFound, 0);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

-(NSRect)signalRect {
    NSRect retRect = [self bounds];
    retRect.size.height -= [self rulerRect].size.height;
    return retRect;
}

-(NSAffineTransform *)sampleTransform {
    NSRect signalRect = [self signalRect];
    NSAffineTransform *retXform = [NSAffineTransform transform];
    [retXform translateXBy:0.0f yBy:signalRect.size.height / 2];
    [retXform scaleXBy:signalRect.size.width / ((CGFloat)_originalSampleDataLength -1 )
                   yBy:signalRect.size.height * _verticalScale / 2];
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

-(NSRect)rectForSampleSelection:(NSRange)aSelection {
    NSRect retRect = [self signalRect];
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
        
        // [self.selectedBorderColor set];
        // [NSBezierPath setDefaultLineWidth:2.0];
        // [NSBezierPath strokeRect:selectedRect];
    }
}

-(void)drawSelectionThumbs {
    if (_selectedSampleRange.location != NSNotFound) {
        NSBezierPath *thumb = [NSBezierPath bezierPath];
        [thumb moveToPoint:NSMakePoint([self selectionRect].origin.x,
                                       [self rulerRect].origin.y + RULER_INSET)];
        [thumb lineToPoint:NSMakePoint([self selectionRect].origin.x,
                                       [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        [thumb lineToPoint:NSMakePoint([self selectionRect].origin.x + [self rulerRect].size.height / 2 - RULER_INSET,
                                       [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        [thumb closePath];
        
        NSBezierPath *endThumb = [NSBezierPath bezierPath];
        [endThumb moveToPoint:NSMakePoint([self selectionRect].origin.x + [self selectionRect].size.width,
                                          [self rulerRect].origin.y + RULER_INSET)];
        [endThumb lineToPoint:NSMakePoint([self selectionRect].origin.x + [self selectionRect].size.width,
                                          [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        [endThumb lineToPoint:NSMakePoint(([self selectionRect].origin.x + [self selectionRect].size.width) - [self rulerRect].size.height / 2 + RULER_INSET,
                                          [self rulerRect].origin.y + [self rulerRect].size.height / 2)];
        
        [endThumb closePath];
        
        [self.selectedBorderColor set];
        [thumb fill];
        [endThumb fill];
    }
}

- (void)drawRuler {
    /* ruler */
    
    NSRect rulerRect = [self rulerRect];
    
    NSGradient *rulerGradient = [[NSGradient alloc] initWithStartingColor:[NSColor controlLightHighlightColor]
                                                              endingColor:[NSColor controlHighlightColor]];
    
    [rulerGradient drawInRect:rulerRect angle:270.0f];
    
    CGFloat tickHeight = rulerRect.size.height - (RULER_INSET * 2);
    CGFloat minorTickHeight = tickHeight * RULER_MINOR_TICK_FACTOR;
    NSUInteger i, xpt;
    
    [[NSColor controlDarkShadowColor] set];
    [NSBezierPath setDefaultLineWidth:1.0f];
    for (i = 0; i < _originalSampleDataLength; i += _rulerMajorTicks) {
        xpt = [self sampleToXPoint:i];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_INSET)
                                  toPoint:NSMakePoint(xpt, rulerRect.origin.y+ tickHeight)];
    }
    for (i = 0; i < _originalSampleDataLength; i += _rulerMinorTicks) {
        if (i % _rulerMajorTicks) {
            xpt = [self sampleToXPoint:i];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xpt, rulerRect.origin.y+ RULER_INSET)
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





- (void)dealloc {
    [self removeObserver:self forKeyPath:@"foregroundColor"];
    [self removeObserver:self forKeyPath:@"backgroundColor"];
    [self removeObserver:self forKeyPath:@"selectedColor"];
    [self removeObserver:self forKeyPath:@"selectedBorderColor"];
    [self removeObserver:self forKeyPath:@"selectedSampleRange"];
    [self removeObserver:self forKeyPath:@"displaysRuler"];
    [self removeObserver:self forKeyPath:@"allowsSelection"];
    
}

@end
