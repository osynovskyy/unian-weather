//
//  ForecastIO_Data_ProviderPlugIn.m
//  ForecastIO Data Provider
//
//  Created by Oleksii Osynovskyi on 6/22/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

// It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering
#import <OpenGL/CGLMacro.h>

#import "ForecastIO_Data_ProviderPlugIn.h"

#define	kQCPlugIn_Name				@"ForecastIO Data Provider"
#define	kQCPlugIn_Description		@"Provides data from forecast.io"
#define kQCPlugIn_Copyright         @"©2015 Osynovskyy.com"

@implementation ForecastIO_Data_ProviderPlugIn

// Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
//@dynamic inputFoo, outputBar;

@dynamic inputLatitude, inputLongitude; //coordinates
@dynamic inputDateAndTime;
@dynamic inputForecastAPIKey;

@dynamic outputOK;

@dynamic outputIcon;
@dynamic outputTemperature;
@dynamic outputWindDirection, outputWindStrength;

+ (NSDictionary *)attributes
{
	// Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
    return @{QCPlugInAttributeNameKey:kQCPlugIn_Name,
             QCPlugInAttributeDescriptionKey:kQCPlugIn_Description,
             QCPlugInAttributeCopyrightKey:kQCPlugIn_Copyright};
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	// Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
	return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
	// Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
    return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode)timeMode
{
	// Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	return kQCPlugInTimeModeNone;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		// Allocate any permanent resource required by the plug-in.
	}
	
	return self;
}

- (NSString*) weatherIconForCondition: (NSString *) condition {
    
    NSString *code = [condition lowercaseString];
    
    const NSDictionary *forecastIOCodes = @{
                                            @"clear-day": @"clear-sky",
                                            @"clear-night": @"clear-sky",
                                            @"rain": @"rain",
                                            @"snow": @"snow",
                                            @"sleet": @"snow",
                                            @"fog": @"fog",
                                            @"wind": @"smoke",
                                            @"cloudy": @"broken-clouds",
                                            @"party-cloudy-day": @"few-clouds",
                                            @"party-cloudy-night": @"few-clouds",
                                            @"hail": @"freezing-rain",
                                            @"thunderstorm": @"thunderstrom",
                                            @"tornado": @"tronado"
                                             };
    
    return forecastIOCodes[code];
}

@end

@implementation ForecastIO_Data_ProviderPlugIn (Execution)

- (BOOL)startExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	// Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	
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
    
    self.outputOK = NO;
    
    if ([self.inputForecastAPIKey isEqualToString:@""]) {
        NSLog(@"ForecastIO API key is empty");
        return NO;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm";
    
    NSDate *inDate;
    
    if ([self.inputDateAndTime isEqualToString:@""]) {
        inDate = [[NSDate alloc] init];
    } else {
        inDate = [dateFormatter dateFromString: self.inputDateAndTime];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/%0.2f,%0.2f?units=si",
                           self.inputForecastAPIKey,
                           self.inputLatitude,
                           self.inputLongitude]; //
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if (nil == data) {
        NSLog(@"-sendSynchronousRequest: return nill.");
        return YES;
    }
    
    NSError *error = nil;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (nil != error) {
        NSLog(@"Error parsing JSON");
        return YES;
    }
    
    if ([json objectForKey:@"error"]) {
        NSLog(@"ForecastIO: %@", json[@"error"]);
        return YES;
    }
   
    NSDictionary *forecast;
    
    for (forecast in json[@"hourly"][@"data"]) {
        
        NSDate *forecastDate = [NSDate dateWithTimeIntervalSince1970: [forecast[@"time"] longValue]];
        
        if ([forecastDate compare:inDate] == NSOrderedDescending || [forecastDate compare:inDate] == NSOrderedSame)
            break;
    }
    
    self.outputTemperature = [forecast[@"temperature"] doubleValue];
    
    self.outputWindDirection = [forecast[@"windBearing"] doubleValue];
    self.outputWindStrength = [forecast[@"windSpeed"] doubleValue];
    
    self.outputIcon = [self weatherIconForCondition: forecast[@"icon"]];
    
    self.outputOK = YES;
    
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
