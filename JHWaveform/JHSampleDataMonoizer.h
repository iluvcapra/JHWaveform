//
//  JHSampleDataTransformer.h
//  JHWaveformView
//
//  Created by Jamie Hardt on 11/22/12.
//  Copyright (c) 2012 Jamie Hardt. All rights reserved.
//

#import "JHSampleDataProvider.h"

@interface JHSampleDataMonoizer : JHSampleDataProvider {
    JHSampleDataProvider *_sourceProvider;
}

-(id)initWithSourceProvider:(JHSampleDataProvider *)provider;

@end