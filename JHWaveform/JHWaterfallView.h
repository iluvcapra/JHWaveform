//
//  JHWaterfallView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSignalView.h"

@interface JHWaterfallView : JHSignalView {
    float *_waterfallData;
    NSUInteger _samplesPerFrame;
    NSUInteger _frames;
    
    NSGradient *_intensityGradient;
}

@property (readwrite) NSGradient *intensityGradient;


/* Set data to display. `data` must contain frameCount * samplesPerFrame floats.
 and represent the table of data "flat" */
-(void)setData:(float *)data
        frames:(NSUInteger)frameCount samplesPerFrame:(NSUInteger)samplesPerFrame;

@end
