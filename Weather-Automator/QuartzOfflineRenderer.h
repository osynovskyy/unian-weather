//
//  QuartzOfflineRenderer.h
//  Weather
//
//  Created by Oleksii Osynovskyi on 6/25/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

@import Foundation;
@import Quartz;
@import AVFoundation;

@interface QuartzOfflineRenderer : NSOperation

@property NSSize *outputSize;

@property CMTimeRange timeRange;

@property (readonly) BOOL isFailed;
@property (readonly) BOOL hasAudio;

- (instancetype) initWithCompositionPath:(NSString *)path inputKeys:(NSDictionary *)keys pixelsWide:(int32_t)width pixelsHight:(int32_t)height;
- (BOOL) setupOutputWithURL:(NSURL *)url inPoint:(NSTimeInterval) inPoint outPoint: (NSTimeInterval) outPoint;
- (BOOL) addAudio:(NSURL *)urlSound;

//- (void) main;

@end
