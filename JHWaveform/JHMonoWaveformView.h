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

#import "JHSignalView.h"
@class JHSampleDataProvider;

@interface JHMonoWaveformView : JHSignalView {
    
    NSColor     *_gridColor;

    NSColor     *_lineColor;
    CGFloat     _lineWidth;
    CGFloat     _verticalScale;
    
    
    NSPoint     *_sampleData;
    NSUInteger  _sampleDataLength;
    
    BOOL        _displaysGrid;
    NSUInteger  _gridTicks;
    
    JHSampleDataProvider    *_sampleDataProvider;
}

/* All of the colors of the view are modifiable. foregroundColor, lineColor and
 backgroundColor apply to the waveform itself.  By default, these colors are 
 set to neutral system-defined colors for NSCells */

@property (copy, readwrite) NSColor *gridColor;
@property (copy, readwrite) NSColor *lineColor;


/* This is the width of the waveform line the default is probably the best. */
@property (assign) CGFloat lineWidth;

/* The vertical scale of the waveform.  By default, the waveform is scaled
 so that peaks at -1.0/+1.0 are at the edges of the waveform's rectangle */
@property (assign) CGFloat verticalScale;

/* Draws a waveform with the given sample buffer */
-(void)setWaveform:(const float*)samples length:(NSUInteger)length;

/* Draws a waveform with a sample data provider */
-(void)setSampleDataProvider:(JHSampleDataProvider *)provider;

/* The total number of samples, rather, a convenience for getting whatever
 the client gave for `length` */
@property (readonly) NSUInteger sampleLength;



@property (assign) BOOL displaysGrid;
@property (assign) NSUInteger gridTicks;



@end

