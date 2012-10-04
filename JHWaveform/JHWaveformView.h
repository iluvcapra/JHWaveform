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
    NSColor *_foregroundColor, *_lineColor, *_backgroundColor, *_selectedColor;
    
    CGFloat     _lineWidth;
    CGFloat     _verticalScale;
    
    BOOL        _allowsSelection;
    NSRange     _selectedSampleRange;
    NSUInteger  _selectionAnchor;
    BOOL        _dragging;
    int         _mouseMode;
    
    NSPoint     *_sampleData;
    NSUInteger  _sampleDataLength;
}

@property (copy, readwrite) NSColor *foregroundColor, *lineColor, *backgroundColor, *selectedColor;

@property (assign) CGFloat lineWidth;
@property (assign) CGFloat verticalScale;


@property (assign) NSRange selectedSampleRange;

@property (assign) BOOL allowsSelection;

-(void)setWaveform:(float*)samples length:(NSUInteger)length;


@end

