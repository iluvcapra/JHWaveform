//
//  JHSignalView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JHSignalView : NSView {
    NSColor     *_foregroundColor;
    NSColor     *_backgroundColor;
    NSColor     *_selectedColor;
    NSColor     *_selectedBorderColor;
}

@property (copy, readwrite) NSColor *foregroundColor;
@property (copy, readwrite) NSColor *backgroundColor;
@property (copy, readwrite) NSColor *selectedColor;
@property (copy, readwrite) NSColor *selectedBorderColor;



/*
 These methods are used by subclasses and should be moved out to a separate
 header.
 */

-(CGFloat)sampleToXPoint:(NSUInteger)sampleIdx;
-(NSUInteger)xPointToSample:(CGFloat)xPoint;
-(NSAffineTransform *)sampleTransform;
-(NSRect)signalRect;
-(NSRect)reulerRect;

@end
