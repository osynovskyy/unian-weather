//
//  Weather_SectorPlugIn.m
//  Weather Sector
//
//  Created by Oleksii Osynovskyi on 6/9/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

// It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering
#import <OpenGL/CGLMacro.h>

#import "WeatherSectorPlugIn.h"
#import "WeatherCodes.h"

#import "JKInterpolationMath.h"

#define	kQCPlugIn_Name				@"Weather Sector"
#define	kQCPlugIn_Description		@"Weather Sector Description"


@implementation NSBezierPath (BezierPathQuartzUtilities)
// This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath
{
    long i, numElements;
    
    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;
    
    // Then draw the path elements.
    numElements = [self elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        
        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
                    
                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
                    
                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
                    
                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        
        // Be sure the path is closed or Quartz may not do valid hit detection.
        if (!didClosePath)
            CGPathCloseSubpath(path);
        
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}
@end


@interface SectorImageProvider: NSObject <QCPlugInOutputImageProvider> {

}

//optimization
@property BOOL needUpdate;
@property vImage_Buffer renderBuffer;

@property double scale;

@property NSString *icon;
@property double radius;
@property double windDirection;
@property double windStrength;
@property CGColorRef windColor;
@property double temperature;
@property CGColorRef backgroundColor;

- (void) clean;

@end

@implementation SectorImageProvider

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.needUpdate = YES;
    }
    
    return self;
}

- (NSRect)imageBounds {
    return CGRectMake(0, 0, 2*self.radius, 2*self.radius);
}

- (CGColorSpaceRef)imageColorSpace {
    return CGColorSpaceCreateDeviceRGB();
}

- (NSArray *)supportedBufferPixelFormats {
    return @[
             QCPlugInPixelFormatBGRA8,
             QCPlugInPixelFormatARGB8,
             QCPlugInPixelFormatRGBAf
    ];
}

- (BOOL)renderToBuffer:(void *)baseAddress withBytesPerRow:(NSUInteger)rowBytes pixelFormat:(NSString *)format forBounds:(NSRect)bounds {
    
//    if (_renderBuffer.data == NULL || self.needUpdate) { //Render buffer not created yet, creating
//        _renderBuffer.data = malloc(bounds.size.height*rowBytes);
//        _renderBuffer.width = bounds.size.width;
//        _renderBuffer.height = bounds.size.height;
//        _renderBuffer.rowBytes = rowBytes;
//        
//        self.needUpdate = YES;
//    }
    
    // Declaring destination buffer
    vImage_Buffer destBuffer;
    destBuffer.data = baseAddress;
    destBuffer.width = bounds.size.width;
    destBuffer.height = bounds.size.height;
    destBuffer.rowBytes = rowBytes;
    
    if (self.needUpdate) {
        
        [self clean];
        
        _renderBuffer.data = malloc(bounds.size.height*rowBytes);
        _renderBuffer.rowBytes = rowBytes;
        _renderBuffer.width = bounds.size.width;
        _renderBuffer.height = bounds.size.height;
        
        CGContextRef context = CGBitmapContextCreate(_renderBuffer.data, bounds.size.width, bounds.size.height, 8, rowBytes, [self imageColorSpace], kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
        
        CGContextClearRect(context, bounds);
        
        // Base 100px and scaling for any size
        
        double scale = (MAX(bounds.size.width, bounds.size.height)/100);
        
        CGContextScaleCTM(context, scale, scale);
        
        double animation = self.scale;
        double offset = 50*(1-animation);
        
        CGContextTranslateCTM(context, offset, offset);
        CGContextScaleCTM(context, animation, animation);
        
        const CGFloat *colorComponets = CGColorGetComponents(self.backgroundColor);
        
        CGContextSetRGBFillColor(context, colorComponets[2], colorComponets[1], colorComponets[0], colorComponets[3]); //BGRA8
        
        CGContextFillEllipseInRect(context, CGRectMake(3, 3, 94, 94));
        
        
        //Drawing temperature text
        
        CGContextSelectFont(context, "PF DinDisplay Pro Medium", 22, kCGEncodingMacRoman);
        
        CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
        
        NSString *tempString = [NSString stringWithFormat:@"%@%.1f˚", self.temperature >= 0? @" " : @"",roundf(self.temperature*10.0)/10.0];
        
        NSDictionary *attribs = @{NSFontAttributeName: [NSFont fontWithName:@"PF DinDisplay Pro Medium" size:22]};
        
        NSSize textSize = [tempString sizeWithAttributes:attribs];
        
        CGContextShowTextAtPoint(context, 50-textSize.width/2, 15, [tempString cStringUsingEncoding:NSMacOSRomanStringEncoding], [tempString length]);
        
        //Draw horizontal line
        
        NSBezierPath *hLine = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(15, 35, 70, 1) xRadius:0.5 yRadius:0.5];
        
        CGContextAddPath(context, [hLine quartzPath]);
        
        CGContextDrawPath(context, kCGPathFill);
        
        //Draw Icon
        
        NSString *pathToIcon = [[NSBundle bundleForClass:[self class]] pathForResource: [[WeatherCodes codes] objectForKey:self.icon] ofType:@"png"];
        
        CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename([pathToIcon cStringUsingEncoding:NSMacOSRomanStringEncoding]);
        
        CGImageRef icon = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
        
        vImage_Buffer srcBuffer, destBuffer;
        
        vImage_CGImageFormat iconFormat = {
            .bitsPerComponent = (unsigned int)CGImageGetBitsPerComponent(icon),
            .bitsPerPixel = (unsigned int)CGImageGetBitsPerPixel(icon),
            .colorSpace = CGImageGetColorSpace(icon),
            .bitmapInfo = CGImageGetBitmapInfo(icon),
            .version = 0,
            .decode = NULL,
            .renderingIntent = kCGRenderingIntentDefault
        };
        
        vImageBuffer_InitWithCGImage(&srcBuffer, &iconFormat, NULL, icon, kvImageNoFlags);
        
        CGImageRelease(icon);
        
        void *pixelBuffer = malloc(srcBuffer.rowBytes*srcBuffer.height);
        if (NULL == pixelBuffer)
            return NO;
        
        destBuffer.data = pixelBuffer;
        destBuffer.width = srcBuffer.width;
        destBuffer.height = srcBuffer.height;
        destBuffer.rowBytes = srcBuffer.rowBytes;
        
        vImage_Error vError;
        
        const uint8_t map[4] = { 2, 1, 0, 3 };
        vError = vImagePermuteChannels_ARGB8888(&srcBuffer, &destBuffer, map, kvImageNoFlags);
        
        free(srcBuffer.data);
        
        icon = vImageCreateCGImageFromBuffer(&destBuffer, &iconFormat, NULL, NULL, kvImageNoFlags, &vError);
        
        free(destBuffer.data);
        
        CGContextSetShouldAntialias(context, YES);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextDrawImage(context, CGRectMake(21, 36, 58, 58), icon);
        
        CGImageRelease(icon);
        
        //Drawing wind
        
        const CGFloat *inWindColorComponents = CGColorGetComponents(self.windColor);
        
        CGFloat windColorComponets[] = {inWindColorComponents[2], inWindColorComponents[1], inWindColorComponents[0], inWindColorComponents[3]};
        
        CGColorRef windColor = CGColorCreate(self.imageColorSpace, windColorComponets);
        
        CGContextSetStrokeColorWithColor(context, windColor);
        CGContextSetLineWidth(context, 6);
        
        CGContextBeginPath(context);
        
        CGFloat radStrength = degreesToRadians(self.windStrength);
        CGFloat radDirection = -degreesToRadians(self.windDirection-90);
        
        CGContextAddArc(context, 50, 50, 47, radDirection+radStrength/2, radDirection-radStrength/2, 1);
        
        CGContextStrokePath(context);
        
        //Release context
        
        CGContextRelease(context);
        
        self.needUpdate = NO;
    }

    //Final copy render buffer to destination buffer
    vImage_Error error = vImageCopyBuffer(&_renderBuffer, &destBuffer, 4, kvImageNoFlags);
    if (error) {
        NSLog(@"Error: vImageCopyBuffer — %ld", error);
        return NO;
    }
    
    return YES;
}

- (void)clean {
    free(_renderBuffer.data);
    _renderBuffer.width = 0;
    _renderBuffer.height = 0;
    _renderBuffer.rowBytes = 0;
}

@end

@interface WeatherSectorPlugIn () {
}

@property SectorImageProvider *provider;

@end

@implementation WeatherSectorPlugIn

// Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
//@dynamic inputFoo, outputBar;

@dynamic inputAnimationEnable, inputInPoint, inputOutPoint, inputAnimationDuration;
@dynamic inputIcon;
@dynamic inputRadius;
@dynamic inputTemp;
@dynamic inputWindStrength, inputWindDirection, inputWindColor;
@dynamic inputBackgroundColor;

@dynamic outputSector;

+ (NSDictionary *)attributes
{
	// Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
    return @{
             QCPlugInAttributeNameKey:kQCPlugIn_Name,
             QCPlugInAttributeDescriptionKey:kQCPlugIn_Description,
             QCPlugInAttributeCopyrightKey:@"©2015 Osynovskyy.com"
             };
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	// Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
    
    if ([key isEqualToString:@"inputAnimationEnable"]) {
        return @{
                 QCPortAttributeNameKey: @"Enable Animation",
                 QCPortAttributeTypeKey: QCPortTypeBoolean,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithBool:NO]
                 };
    }
    
    if ([key isEqualToString:@"inputInPoint"]) {
        return @{
                 QCPortAttributeNameKey: @"In Point",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:0.0],
                 QCPortAttributeMinimumValueKey: [NSNumber numberWithFloat:0.0]
                 };
    }
    
    if ([key isEqualToString:@"inputOutPoint"]) {
        return @{
                 QCPortAttributeNameKey: @"Out Point",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:2.0],
                 QCPortAttributeMinimumValueKey: [NSNumber numberWithFloat:1.0]
                 };
    }
    
    if ([key isEqualToString:@"inputAnimationDuration"]) {
        return @{
                 QCPortAttributeNameKey: @"Animation Duration",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:1.0],
                 QCPortAttributeMinimumValueKey: [NSNumber numberWithFloat:0.1]
                 };
    }
    
    if ([key isEqualToString:@"inputIcon"]) {
        return @{
                 QCPortAttributeNameKey: @"Icon",
                 QCPortAttributeTypeKey: QCPortTypeString,
                 QCPortAttributeDefaultValueKey: @"200"
                 };
    }
    
    if ([key isEqualToString:@"inputRadius"]) {
        return @{
                 QCPortAttributeNameKey: @"Radius",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:300],
                 QCPortAttributeMinimumValueKey: [NSNumber numberWithFloat:10]
                 };
    }
    
    if ([key isEqualToString:@"inputTemp"]) {
        return @{
                 QCPortAttributeNameKey: @"Temperature",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:17.3]
                 };
    }
    
    if ([key isEqualToString:@"inputWindDirection"]) {
        return @{
                 QCPortAttributeNameKey: @"Wind Direction",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:0.0]
                 };
    }
    
    if ([key isEqualToString:@"inputWindStrength"]) {
        return @{
                 QCPortAttributeNameKey: @"Wind Strength",
                 QCPortAttributeTypeKey: QCPortTypeNumber,
                 QCPortAttributeDefaultValueKey: [NSNumber numberWithFloat:10.0],
                 QCPortAttributeMinimumValueKey: [NSNumber numberWithFloat:10],
                 QCPortAttributeMaximumValueKey: [NSNumber numberWithFloat:360]
                 };
    }
    
    if ([key isEqualToString:@"inputWindColor"]) {
        return @{
                 QCPortAttributeNameKey: @"Wind Sector Color",
                 QCPortAttributeTypeKey: QCPortTypeColor
                 };
    }
    
    if ([key isEqualToString:@"inputBackgroundColor"]) {
        return @{
                 QCPortAttributeNameKey: @"Background Color",
                 QCPortAttributeTypeKey: QCPortTypeColor
                 };
    }
    
    if ([key isEqualToString:@"outputSector"]) {
        return @{
                 QCPortAttributeNameKey: @"Sector",
                 QCPortAttributeTypeKey: QCPortTypeImage
                 };
    }
    
    if ([key isEqualToString:@"outputMask"]) {
        return @{
                 QCPortAttributeNameKey: @"Mask",
                 QCPortAttributeTypeKey: QCPortTypeImage
                 };
    }
    
	return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
	// Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode
{
	// Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	return kQCPlugInTimeModeTimeBase;
}

@end

@implementation WeatherSectorPlugIn (Execution)

- (BOOL)startExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	// Return NO in case of fatal failure (this will prevent rendering of the composition to start).
//    CGLContextObj cgl_ctx = [context CGLContextObj];
    
    self.provider = [[SectorImageProvider alloc] init]; //default value
    
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	/*
	Called by Quartz Composer whenever the plug-in instance needs to execute.
	Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	
	The OpenGL context for rendering can be accessed and defined for CGL macros using:
	CGLContextObj cgl_ctx = [context CGLContextObj];
	*/
    
    double animation = 1.0;
    
    if (self.inputAnimationEnable) {
        if (time < self.inputInPoint || time > self.inputOutPoint + self.inputAnimationDuration)
            animation = 0.0;
        else if (time >= self.inputInPoint && time <= self.inputInPoint+self.inputAnimationDuration) {
            
            CGFloat t = (time - self.inputInPoint)/self.inputAnimationDuration;
            
            animation = JKCubicInOutInterpolation(t, 0, 1);
            self.provider.needUpdate = YES;
        } else if (time >= self.inputOutPoint && time <= self.inputOutPoint+self.inputAnimationDuration) {
            
            CGFloat t = (time - self.inputOutPoint)/self.inputAnimationDuration;
            
            animation = JKCubicInOutInterpolation(t, 1, 0);
            self.provider.needUpdate = YES;
        }
    }
    
    if ([self didValueForInputKeyChange:@"inputRadius"] ||
        [self didValueForInputKeyChange:@"inputAnimationEnable"] ||
        [self didValueForInputKeyChange:@"inputInPoint"] ||
        [self didValueForInputKeyChange:@"inputOutPoint"] ||
        [self didValueForInputKeyChange:@"inputAnimationDuration"] ||
        [self didValueForInputKeyChange:@"inputIcon"] ||
        [self didValueForInputKeyChange:@"inputTemp"] ||
        [self didValueForInputKeyChange:@"inputWindDirection"] ||
        [self didValueForInputKeyChange:@"inputWindStrength"] ||
        [self didValueForInputKeyChange:@"inputWindColor"] ||
        [self didValueForInputKeyChange:@"inputBackgroundColor"])
        self.provider.needUpdate = YES;
    
    self.provider.radius = self.inputRadius;
    
    self.provider.scale = animation;
    
    self.provider.icon = self.inputIcon;
    
    self.provider.backgroundColor = self.inputBackgroundColor;
    self.provider.temperature = self.inputTemp;
    self.provider.windDirection = self.inputWindDirection;
    self.provider.windStrength = self.inputWindStrength;
    self.provider.windColor = self.inputWindColor;
    
    self.outputSector = self.provider;
    
	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
}

@end
