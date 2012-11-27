//
//  _JHBufferedSampleDataProvider.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/27/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"

@interface _JHBufferedSampleDataProvider : JHSampleDataProvider {
    double      _framesPerSecond;
    NSUInteger  _samplesPerFrame;
    NSData      *_sampleDataBuffer;

}

@end
