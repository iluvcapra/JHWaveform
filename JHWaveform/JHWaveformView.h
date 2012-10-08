//
//  JHWaveformView.h
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

#import <Foundation/Foundation.h>

enum JHWaveformViewMouseModes {
    selecting,
    zooming
};

@interface JHWaveformView : NSView {
    NSColor *_foregroundColor, *_lineColor, *_backgroundColor,
    *_selectedColor, *_selectedBorderColor,*_gridColor;
    
    CGFloat     _lineWidth;
    CGFloat     _verticalScale;
    
    BOOL        _allowsSelection;
    NSRange     _selectedSampleRange;
    NSUInteger  _selectionAnchor;
    BOOL        _dragging;
    int         _mouseMode;
    
    NSPoint     *_sampleData;
    NSUInteger  _sampleDataLength;
    NSUInteger  _originalSampleDataLength;
    
    BOOL        _displaysRuler;
    BOOL        _displaysGrid;
    NSUInteger  _rulerMajorTicks, _rulerMinorTicks;
    NSUInteger  _gridTicks;
}

/* All of the colors of the view are modifiable. foregroundColor, lineColor and
 backgroundColor apply to the waveform itself.  By default, these colors are 
 set to neutral system-defined colors for NSCells */

@property (copy, readwrite) NSColor *foregroundColor,
                                    *lineColor,
                                    *backgroundColor,
                                    *selectedColor,
                                    *selectedBorderColor,
                                    *gridColor,
                                    *rulerGradientBeginColor,
                                    *rulerGradientEndColor,
                                    *rulerTicksColor,
                                    *outerBorderColor;

/* This is the width of the waveform line the default is probably the best. */
@property (assign) CGFloat lineWidth;

/* The vertical scale of the waveform.  By default, the waveform is scaled
 so that peaks at -1.0/+1.0 are at the edges of the waveform's rectangle */
@property (assign) CGFloat verticalScale;

/*
 The selected sample range is sorta under construction, right now it gives a 
 result in the view's internal sample buffer, which may be shorter than the 
 sample buffer originally given to the view.
 */
@property (assign) BOOL allowsSelection;
@property (assign) NSRange selectedOriginalSampleRange;

@property (assign) BOOL displaysRuler, displaysGrid;
@property (assign) NSUInteger rulerMajorTicks, rulerMinorTicks, gridTicks;

-(void)setWaveform:(float*)samples length:(NSUInteger)length;

/*
 These two views are used by subclasses and should be moved out to a separate
 header.
 */
-(CGFloat)coalescedSampleToXPoint:(NSUInteger)sampleIdx;

-(NSUInteger)xPointToCoalescedSample:(CGFloat)xPoint;


@end

