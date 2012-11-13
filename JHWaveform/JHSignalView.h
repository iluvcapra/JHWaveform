//
//  JHSignalView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>

enum JHWaveformViewMouseModes {
    selecting,
    zooming
};

/* JHSignalView is an abstract superclass that provides machinery common to 
 drawing a signal along a time dimension in a rectangle.
 
 It draws a background, provides some getters and setters for colors, draws a 
 ruler, and manages selection.
 
 A subclass of JHSignalView must do two things
 
 - Implement drawSignalInRect: to draw your rendition of the signal.  The 
 default implementation causes an assertion to fail.
 - set _originalSampleDataLength when the length of the sample data is known.
 
 */

@interface JHSignalView : NSView {
    NSColor     *_foregroundColor;
    NSColor     *_backgroundColor;
    NSColor     *_selectedColor;
    NSColor     *_selectedBorderColor;
    
    BOOL        _allowsSelection;
    NSRange     _selectedSampleRange;
    
    NSUInteger  _selectionAnchor;
    BOOL        _dragging;
    int         _mouseMode;
    
//    NSUInteger  _rulerMajorTicks, _rulerMinorTicks;
    NSUInteger  _originalSampleDataLength;
//    BOOL        _displaysRuler;
}

@property (copy, readwrite) NSColor *foregroundColor;
@property (copy, readwrite) NSColor *backgroundColor;
@property (copy, readwrite) NSColor *selectedColor;
@property (copy, readwrite) NSColor *selectedBorderColor;

//@property (assign) BOOL displaysRuler;
//@property (assign) NSUInteger rulerMajorTicks, rulerMinorTicks;

/*
 The current selection in the waveform.  This is an NSRange in terms of 
 
 If there is no selection, @selectedSampleRange will be {NSNotFound,0}
 */
@property (assign) BOOL allowsSelection;
@property (assign) NSRange selectedSampleRange;

/*
 These methods are used by subclasses and should be moved out to a separate
 header.
 */

-(CGFloat)sampleToXPoint:(NSUInteger)sampleIdx;
-(NSUInteger)xPointToSample:(CGFloat)xPoint;
-(NSAffineTransform *)sampleTransform;
-(NSRect)signalRect;
//-(NSRect)rulerRect;

-(void)drawSignalInRect:(NSRect)dirtyRect;

@end
