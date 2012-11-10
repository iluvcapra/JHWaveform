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
    
    NSUInteger  _rulerMajorTicks, _rulerMinorTicks;
    NSUInteger  _originalSampleDataLength;
    BOOL        _displaysRuler;
}

@property (copy, readwrite) NSColor *foregroundColor;
@property (copy, readwrite) NSColor *backgroundColor;
@property (copy, readwrite) NSColor *selectedColor;
@property (copy, readwrite) NSColor *selectedBorderColor;

@property (assign) BOOL displaysRuler;

@property (assign) NSUInteger rulerMajorTicks, rulerMinorTicks;

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
-(NSRect)rulerRect;

-(void)drawSignalInRect:(NSRect)dirtyRect;

@end
