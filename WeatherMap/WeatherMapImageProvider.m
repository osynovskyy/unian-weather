//
//  WeatheMapImageProvider.m
//  Weather Sector
//
//  Created by Oleksii Osynovskyi on 6/18/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#include <Accelerate/Accelerate.h>

#import <OpenGL/CGLMacro.h>

#import "WeatherMapImageProvider.h"

@implementation WeatherMapImageProvider

- (instancetype)init {
    self = [super init];
    
    if (self) {
        
        CGImageRef imageMap;
        
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"ua-map" ofType:@"png"];
        
        const uint8_t map[4] = { 3, 0, 1, 2 };
        
        CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename([path cStringUsingEncoding:NSMacOSRomanStringEncoding]);
        
        
        imageMap = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
        
        
        vImage_CGImageFormat imageMapFormat = {
            .bitsPerComponent = (unsigned int)CGImageGetBitsPerComponent(imageMap),
            .bitsPerPixel = (unsigned int)CGImageGetBitsPerPixel(imageMap),
            .colorSpace = CGImageGetColorSpace(imageMap),
            .bitmapInfo = CGImageGetBitmapInfo(imageMap),
            .version = 0,
            .decode = NULL,
            .renderingIntent = kCGRenderingIntentDefault
        };
        
        vImageBuffer_InitWithCGImage(&bufferMap, &imageMapFormat, NULL, imageMap, kvImageNoFlags);
        
        vImagePermuteChannels_ARGB8888(&bufferMap, &bufferMap, map, kvImageNoFlags);
        
        vImageBuffer_Init(
                          &renderBuffer,
                          (vImagePixelCount)CGImageGetHeight(imageMap),
                          (vImagePixelCount)CGImageGetWidth(imageMap),
                          (uint32_t)CGImageGetBitsPerPixel(imageMap),
                          kvImageNoFlags);
        
        CGImageRelease(imageMap);
        
        
        
        CGImageRef imageOutlines;
        
        path = [[NSBundle bundleForClass:[self class]] pathForResource:@"ua-map-outlines-cities" ofType:@"png"];
        
        dataProvider = CGDataProviderCreateWithFilename([path cStringUsingEncoding:NSMacOSRomanStringEncoding]);
        
        imageOutlines = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
        
        vImage_CGImageFormat imageOutlineFormat = {
            .bitsPerComponent = (unsigned int)CGImageGetBitsPerComponent(imageOutlines),
            .bitsPerPixel = (unsigned int)CGImageGetBitsPerPixel(imageOutlines),
            .colorSpace = CGImageGetColorSpace(imageOutlines),
            .bitmapInfo = CGImageGetBitmapInfo(imageOutlines),
            .version = 0,
            .decode = NULL,
            .renderingIntent = kCGRenderingIntentDefault
        };
        
        vImageBuffer_InitWithCGImage(&bufferOutline, &imageOutlineFormat, NULL, imageOutlines, kvImageNoFlags);
        
        vImagePermuteChannels_ARGB8888(&bufferOutline, &bufferOutline, map, kvImageNoFlags);
        
        CGImageRelease(imageOutlines);
        
        self.overImage = nil;
    }
    
    return self;
}

- (NSRect)imageBounds {
    return CGRectMake(0, 0, renderBuffer.width, renderBuffer.height);
}

- (CGColorSpaceRef)imageColorSpace {
    return CGColorSpaceCreateDeviceRGB();
}

- (NSArray *)supportedBufferPixelFormats {
    return @[QCPlugInPixelFormatARGB8];
}

- (BOOL)renderToBuffer:(void *)baseAddress withBytesPerRow:(NSUInteger)rowBytes pixelFormat:(NSString *)format forBounds:(NSRect)bounds {

    
    //Declaring destination buffer
    
    vImage_Buffer destBuffer;
    
    destBuffer.data = baseAddress;
    destBuffer.width = bounds.size.width;
    destBuffer.height = bounds.size.height;
    destBuffer.rowBytes = rowBytes;
    
    vImage_Error error; //error variable
    
    if (self.needUpdate == YES) {
        
        CGContextRef context = CGBitmapContextCreate(bufferMap.data,
                                                     bounds.size.width,
                                                     bounds.size.height,
                                                     8, rowBytes,
                                                     [self imageColorSpace],
                                                     kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault);
        
        if (!context)
            return NO;
        
        //    CGContextClearRect(context, bounds);
        
        NSString *pathToIcon = [[NSBundle bundleForClass:[self class]] pathForResource: @"west-1" ofType:@"png"];
        
        CGDataProviderRef dataProvider =  CGDataProviderCreateWithFilename([pathToIcon cStringUsingEncoding:NSMacOSRomanStringEncoding]);
        
        CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider,  NULL, NO, kCGRenderingIntentDefault);
        
        CGContextDrawImage(context, CGRectMake(655, 863, CGImageGetWidth(image), CGImageGetHeight(image)), image);
        
        CGImageRelease(image);
        
        CGDataProviderRelease(dataProvider);
        
        CGContextRelease(context);
        
        vImage_Buffer tempBuffer;
        
        tempBuffer.data = malloc(bounds.size.height*rowBytes);
        tempBuffer.width = bounds.size.width;
        tempBuffer.height = bounds.size.height;
        tempBuffer.rowBytes = rowBytes;
        
        error = vImageAlphaBlend_ARGB8888(&bufferOutline, &bufferMap, &tempBuffer, kvImageNoFlags);
        
        if (error){
            NSLog(@"Error alpha blending images: %ld", error);
        }
        
        uint8_t backColor[4] = {0, 0, 0, 0};
        
        uint32_t radius = (uint32_t) self.defocus;
        radius = radius - (radius%2) + 1;
        
        if (radius == 1)
            error = vImageCopyBuffer(&tempBuffer, &renderBuffer, 4, kvImageNoFlags);
        else
            error = vImageBoxConvolve_ARGB8888(&tempBuffer,
                                               &renderBuffer,
                                               NULL,
                                               0, 0,
                                               radius, radius,
                                               backColor,
                                               kvImageBackgroundColorFill);
        
        if (error){
            NSLog(@"Error copy or convolving images: %ld", error);
        }
        
        if (self.overImage) {
            if (![self.overImage lockBufferRepresentationWithPixelFormat:QCPlugInPixelFormatARGB8 colorSpace:[self.overImage imageColorSpace] forBounds:[self.overImage imageBounds]]) {
                NSLog(@"Unable lock image representation");
            }
            
            vImage_Buffer overImageBuffer;
            
            overImageBuffer.data = (void*)[self.overImage bufferBaseAddress];
            overImageBuffer.rowBytes = [self.overImage bufferBytesPerRow];
            overImageBuffer.width = [self.overImage bufferPixelsWide];
            overImageBuffer.height = [self.overImage bufferPixelsHigh];
            
            error = vImagePremultipliedAlphaBlend_ARGB8888(&overImageBuffer, &renderBuffer, &tempBuffer, kvImageCopyInPlace);
            
            if (error)
                NSLog(@"Unable blend over image with produced. %ld", error);
            
            error = vImageCopyBuffer(&tempBuffer, &renderBuffer, 4, kvImageNoFlags);
            
            if (error)
                NSLog(@"Unable copy buffers. %ld", error);
            
            [self.overImage unlockBufferRepresentation];
        }
        
        free(tempBuffer.data);
        
        self.needUpdate = NO;
    }
    
    //Final copying from render buffer to destination buffer
    
    error = vImageCopyBuffer(&renderBuffer, &destBuffer, 4, kvImageNoFlags);
    
    if (error)
        NSLog(@"Error copy buffer without update: %ld", error);

    
    return (error ? NO : YES);
}

- (void)clean {
    free(bufferMap.data);
    free(bufferOutline.data);
    
    free(renderBuffer.data);
}

@end
