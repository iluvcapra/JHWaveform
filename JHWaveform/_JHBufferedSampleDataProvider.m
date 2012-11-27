//
//  _JHBufferedSampleDataProvider.m
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/27/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "_JHBufferedSampleDataProvider.h"

@implementation _JHBufferedSampleDataProvider


-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock{
    NSRange maxRange = NSMakeRange(0, [self framesLength]);
    NSRange retRange = NSIntersectionRange(aRange, maxRange);
    
    yieldBlock((float *)[_sampleDataBuffer bytes] +
               retRange.location * _samplesPerFrame,retRange);
    
}

-(NSUInteger)framesLength {
    return [_sampleDataBuffer length] / (sizeof(float) * _samplesPerFrame);
}

-(double)framesPerSecond {
    return _framesPerSecond;
}

-(NSUInteger)samplesPerFrame {
    return _samplesPerFrame;
}

@end
