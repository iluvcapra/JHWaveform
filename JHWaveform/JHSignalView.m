//
//  JHSignalView.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSignalView.h"

#define RULER_HEIGHT            25

@implementation JHSignalView

@synthesize foregroundColor                 = _foregroundColor;
@synthesize backgroundColor                 = _backgroundColor;
@synthesize selectedColor                   = _selectedColor;
@synthesize selectedBorderColor             = _selectedBorderColor;

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


@end
