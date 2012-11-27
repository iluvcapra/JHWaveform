//
//  JHSampleDataProvider.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/27/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JHSampleDataProvider <NSObject>

-(void)yieldFramesInRange:(NSRange)aRange
                  toBlock:(void(^)(float *samples, NSRange outRange))yieldBlock;

-(NSUInteger)framesLength;
-(double)framesPerSecond;
-(NSUInteger)samplesPerFrame;

@end
