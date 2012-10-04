//
//  JHWaveformView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JHWaveformView : NSView {
    NSColor *_foregroundColor, *_lineColor, *_backgroundColor, *_selectedColor;
    
    CGFloat _lineWidth;
//    CGFloat _lineFlatness;
    
    NSRange     _selectedSampleRange;
    NSUInteger  _selectionOrigin;
    BOOL        _dragging;
    
    NSPoint *_sampleData;
    NSUInteger _sampleDataLength;
}

@property (copy, readwrite) NSColor *foregroundColor, *lineColor, *backgroundColor, *selectedColor;
@property (assign) CGFloat lineWidth;

@property (assign) NSRange selectedSampleRange;

-(void)setWaveform:(float*)samples length:(NSUInteger)length;

@end

