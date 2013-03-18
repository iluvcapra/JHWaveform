//
//  JHWaterfallView.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/10/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSignalView.h"
#import "JHSampleDataProvider.h"

@interface JHWaterfallView : JHSignalView {
    float *_waterfallData;
    NSUInteger  _samplesPerFrame;
    NSUInteger  _frames;
    
    NSGradient  *_intensityGradient;
    float       _backgroundThreshold;
    
    NSBitmapImageRep *_precalculatedImageRep;
    
    JHSampleDataProvider    *_sampleDataProvider;
}

@property (readwrite) NSGradient *intensityGradient;
@property (readwrite) float backgroundThreshold;

/* Set data to display. `data` must contain frameCount * samplesPerFrame floats.
 and represent the table of data "flat" */
-(void)setData:(float *)data
        frames:(NSUInteger)frameCount samplesPerFrame:(NSUInteger)samplesPerFrame;

-(void)setSampleDataProvider:(JHSampleDataProvider *)provider;

@end
