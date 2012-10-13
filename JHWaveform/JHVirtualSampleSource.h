//
//  JHVirtualSampleBuffer.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 10/13/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//



@protocol JHVirtualSampleSource

-(NSUInteger)sampleCount;

-(NSRange)rangeOfSamplesInRange:(NSRange)inRange;

-(void)samplesInRange:(NSRange)fromRange
           intoBuffer:(float *)outBuffer;

-(void)copySamplesInRange:(NSRange)fromRange
               intoBuffer:(float *)outBuffer
                   length:(NSUInteger)length;

@end