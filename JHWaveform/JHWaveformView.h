//
//  JHWaveformView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/3/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JHWaveformView : NSView {
    NSColor *_foregroundColor, *_lineColor, *_backgroundColor;
    
    CGFloat _lineWidth;
    
    NSPoint *_sampleData;
    NSUInteger _sampleDataLength;
}

@property (copy, readwrite) NSColor *foregroundColor, *lineColor, *backgroundColor;
@property (assign) CGFloat lineWidth;

-(void)setWaveform:(float*)samples length:(NSUInteger)length;

@end

