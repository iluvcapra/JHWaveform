//
//  JHWaveformView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

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

@property (copy, readwrite) NSColor *foregroundColor, *lineColor, *backgroundColor, *selectedColor,
*selectedBorderColor, *gridColor, *rulerGradientBeginColor,*rulerGradientEndColor,*rulerTicksColor,*outerBorderColor;

@property (assign) CGFloat lineWidth;
@property (assign) CGFloat verticalScale;

@property (assign) BOOL allowsSelection;
@property (assign) NSRange selectedSampleRange;

@property (assign) BOOL displaysRuler, displaysGrid;
@property (assign) NSUInteger rulerMajorTicks, rulerMinorTicks, gridTicks;

-(void)setWaveform:(float*)samples length:(NSUInteger)length;

-(CGFloat)sampleToXPoint:(NSUInteger)sampleIdx;

-(NSUInteger)xPointToSample:(CGFloat)xPoint;


@end

