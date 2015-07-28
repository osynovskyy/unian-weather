
//  QuartzOfflineRenderer.m
//  Weather
//
//  Created by Oleksii Osynovskyi on 6/25/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#import "QuartzOfflineRenderer.h"

@interface QuartzOfflineRenderer () {
    BOOL finished;
    BOOL ready;
    BOOL failed;
}

@property (nonatomic, strong) QCRenderer *renderer;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;

@end

@implementation QuartzOfflineRenderer

#pragma mark — NSOperation

- (BOOL) isFinished {
    return finished;
}

- (BOOL) isReady {
    return ready;
}

- (BOOL) isFailed {
    return failed;
}

#pragma mark — inits

- (instancetype) init {
    
    NSLog(@"Error: Use initWithCompositionPath: pixelsWide: pixelsHight.");
    
    return [self initWithCompositionPath:nil
                               inputKeys:nil
                              pixelsWide:0
                             pixelsHight:0];
}

- (instancetype) initWithCompositionPath:(NSString *)path inputKeys:(NSDictionary *)keys pixelsWide:(int32_t)width pixelsHight:(int32_t)height {
    
    if (![path length] || (width < 16) || (height < 16))
        return nil;
    
    self = [super init];
    
    if (self) {
        CGColorSpaceRef colorSpace;
        QCComposition *composition;
        
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        
        composition = [QCComposition compositionWithFile:path];
       
        if (composition)
            self.renderer = [[QCRenderer alloc] initOffScreenWithSize:NSMakeSize(width, height)
                                                           colorSpace:colorSpace
                                                          composition:composition];
        
        for (NSString *key in keys) { //can throw exception, be careful
            if ([self.renderer setValue: [keys objectForKey:key] forInputKey: key] == NO) {
                NSLog(@"ERROR: Couldn't set inputKeys");
                return nil;
            }
            NSLog(@"OK: Initialized for date %@", [self.renderer valueForInputKey: key ] );
        }
        
        CGColorSpaceRelease(colorSpace);
        
        if (self.renderer == nil)
            return nil;
        
        finished = NO;
        ready = NO;
    }
    
    return self;
}

#pragma mark — Working with AVFoundation

- (BOOL) setupOutputWithURL:(NSURL *)url inPoint:(NSTimeInterval) inPoint outPoint: (NSTimeInterval) outPoint {
    
    NSError *error;
    
    //Setting time range
    
    self.timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(inPoint, 50), CMTimeMakeWithSeconds(outPoint-inPoint, 50));
    
    //Initalizing AssetWriter, creating file in temp folder
    
    NSURL *movieURL = url;
    
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    
    unlink([[movieURL path] cStringUsingEncoding:NSMacOSRomanStringEncoding]);
    
    self.assetWriter = [[AVAssetWriter alloc] initWithURL: movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    
    if (error) {
        NSLog(@"ERROR: -initWithURL: %@", error);
        return NO;
    }
    
    //PAL color settings
    
    NSMutableDictionary *colorSettings = [NSMutableDictionary dictionary];
    
    [colorSettings setObject:AVVideoColorPrimaries_EBU_3213 forKey:AVVideoColorPrimariesKey];
    [colorSettings setObject:AVVideoTransferFunction_ITU_R_709_2 forKey:AVVideoTransferFunctionKey];
    [colorSettings setObject:AVVideoYCbCrMatrix_ITU_R_601_4 forKey:AVVideoYCbCrMatrixKey];
    
    NSDictionary *cleanAperture = @{AVVideoCleanApertureWidthKey: @(703),
                                    AVVideoCleanApertureHeightKey: @(576),
                                    AVVideoCleanApertureHorizontalOffsetKey: @(0),
                                    AVVideoCleanApertureVerticalOffsetKey: @(0)};
    
    //Using Apple Prores 422 Codec for output PAL
    
    NSDictionary *videoSettings = @{
                                    AVVideoCodecKey: AVVideoCodecAppleProRes422, //@"dvpp",
                                    AVVideoScalingModeKey: AVVideoScalingModeResize,
                                    AVVideoWidthKey: @(720),
                                    AVVideoHeightKey: @(576),
                                    AVVideoPixelAspectRatioKey: @{AVVideoPixelAspectRatioHorizontalSpacingKey: @(59), AVVideoPixelAspectRatioVerticalSpacingKey: @(54)},
                                    AVVideoCleanApertureKey: cleanAperture,
                                    AVVideoColorPropertiesKey: colorSettings
                                    };

    
    //Creating video input
    
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    if (!self.videoInput) {
        NSLog(@"ERROR: -assetWriterInputWithMediaType: returns nil");
        return NO;
    }
    
    //Adding input to writer
    
    [self.assetWriter addInput: self.videoInput];
    
    //PixelBufferAdaptor helps to convert data
    
    NSDictionary *pixelBufferAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @(kCVPixelFormatType_32ARGB), kCVPixelBufferPixelFormatTypeKey,
                                      @(788), kCVPixelBufferWidthKey,
                                      @(576), kCVPixelBufferHeightKey,
                                      nil];
    
    self.pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor
                               assetWriterInputPixelBufferAdaptorWithAssetWriterInput: self.videoInput
                               sourcePixelBufferAttributes:pixelBufferAttrs];
    
    if (!self.pixelBufferAdaptor) {
        NSLog(@"ERROR: -assetWriterInputPixelBufferAdaptorWithAssetWriterInput: retunrns nil");
        return NO;
    }
    
    //Test render
//    
//    if ([self pixelBufferForTime: ] == nil) {
//        NSLog(@"ERROR: -pixelBufferForTime: returns nil");
//        return NO;
//    }
    
    ready = YES;
    
    return YES;
}

- (void)main {
 
    if (![self isReady]) {
        NSLog(@"ERROR: Operation is not ready for execution.");
        failed = YES;
        return;
    }
    
    finished = NO;
    failed = NO;
    
    [self.assetWriter startWriting];
    
    [self.assetWriter startSessionAtSourceTime: self.timeRange.start];
    
    dispatch_queue_t work_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//dispatch_queue_create("com.osynovskyy.weather-automator", DISPATCH_QUEUE_SERIAL);
        
    __block CMTime renderTime = self.timeRange.start;
    
    [self.videoInput requestMediaDataWhenReadyOnQueue:work_queue usingBlock:^{
        while ([self.videoInput isReadyForMoreMediaData]) {
            
            //getting lower field
            
            CVPixelBufferRef lowerField = [self pixelBufferForTime: CMTimeGetSeconds(renderTime)];
            
            if (lowerField == nil) {
                NSLog(@"ERROR: -pixelBufferForTime: returns nil at time %f", CMTimeGetSeconds(renderTime));
                failed = YES;
                break;
            }
            
            //getting upper field
            
            renderTime.value++; //half frime
            
            CVPixelBufferRef upperField = [self pixelBufferForTime: CMTimeGetSeconds(renderTime)];
            
            if (upperField == nil) {
                NSLog(@"ERROR: -pixelBufferForTime: returns nil at time %f", CMTimeGetSeconds(renderTime));
                failed = YES;
                break;
            }
            
            //locking pixel buffers base addresses
            CVReturn status = CVPixelBufferLockBaseAddress(lowerField, 1);
            status = CVPixelBufferLockBaseAddress(upperField, 1);
            
            if (status != kCVReturnSuccess) {
                failed = YES;
                NSLog(@"ERROR: CVPixelBufferLockBaseAddress() error: %d", status);
                break;
            }
            
            //getting pointers to base addresses
            void *baseAddressLowerField = CVPixelBufferGetBaseAddress(lowerField);
            void *baseAddressUpperField = CVPixelBufferGetBaseAddress(upperField);
            
            if (baseAddressLowerField == NULL || baseAddressUpperField == NULL) {
                failed = YES;
                NSLog(@"ERROR: CVPixelBufferGetBaseAddress(() returns NULL");
                break;
            }
            
            size_t bytesPerRow = CVPixelBufferGetBytesPerRow(lowerField);
            size_t height = CVPixelBufferGetHeight(lowerField);
            
            //providing fields by copying rows, lower field first order
            for (size_t row = 0; row < height-1; row+=2) {
                
                void *to = baseAddressLowerField+row*bytesPerRow;
                void *from = baseAddressUpperField+row*bytesPerRow;
                
                memcpy(to, from, bytesPerRow);
            }
            
            //unblocking base addresses
            status = CVPixelBufferUnlockBaseAddress(lowerField, 1);
            status = CVPixelBufferUnlockBaseAddress(upperField, 1);
            
            if (status != kCVReturnSuccess) {
                failed = YES;
                NSLog(@"ERROR: CVPixelBufferUnlockBaseAddress() error: %d", status);
                break;
            }
            
            //writing pixel buffer
            
            if ([self.pixelBufferAdaptor appendPixelBuffer:lowerField withPresentationTime: CMTimeConvertScale(renderTime, 25, kCMTimeRoundingMethod_RoundTowardZero)] == NO) {
                failed = YES;
                NSLog(@"ERROR: -appendPixelBuffer: error");
                break;
            }
            
            CFRelease(lowerField);
            CFRelease(upperField);
            
            renderTime.value++;
            
            // checking end of render range
            
            if (!CMTimeRangeContainsTime(self.timeRange, renderTime)) {
                
                [self.videoInput markAsFinished];
                [self.assetWriter finishWritingWithCompletionHandler:^{
                    NSLog(@"OK: Rendered %lld half frames.", renderTime.value);
                    failed = NO;
                    finished = YES;
                }];
                
                break;
            }
        }
    }];
    
    //loop for waiting until everything will done
    while (!([self isFinished] || [self isFailed])) {
    }
    
    finished = YES;
}

- (CVPixelBufferRef) pixelBufferForTime: (NSTimeInterval)time {
    
    if (![self.renderer renderAtTime:time arguments:nil])
        return nil;
    
    CVPixelBufferRef pixelBuffer = (__bridge_retained CVPixelBufferRef)[self.renderer createSnapshotImageOfType:@"CVPixelBuffer"];
    
    return pixelBuffer;
}

#pragma mark — Error handling

- (void) showError: (NSError *) error {
    NSLog(@"%@: %@", [self class], error);
}

@end
