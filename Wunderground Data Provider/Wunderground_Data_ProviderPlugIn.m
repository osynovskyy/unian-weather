//
//  Wunderground_Data_ProviderPlugIn.m
//  Wunderground Data Provider
//
//  Created by Oleksii Osynovskyi on 6/22/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

// It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering
#import <OpenGL/CGLMacro.h>

#import "Wunderground_Data_ProviderPlugIn.h"

#define	kQCPlugIn_Name				@"Wunderground Data Provider"
#define	kQCPlugIn_Description		@"Provides data from wunderground.com"
#define kQCPlugIn_Copyright         @"©2015 Osynovskyy.com"

@implementation Wunderground_Data_ProviderPlugIn

// Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
//@dynamic inputFoo, outputBar;

@dynamic inputLatitude, inputLongitude; //coordinates
@dynamic inputDateAndTime;
@dynamic inputWundergroundAPIKey;

@dynamic outputOK;

@dynamic outputIcon;
@dynamic outputTemperature;
@dynamic outputWindDirection, outputWindStrength;

+ (NSDictionary *)attributes
{
	// Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
    return @{QCPlugInAttributeNameKey:kQCPlugIn_Name, QCPlugInAttributeDescriptionKey:kQCPlugIn_Description};
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
    
    const NSDictionary *wundergroundCodes = @{
                                              @"light drizzle": @"light-drizzle",
                                              @"drizzle": @"drizzle",
                                              @"heavy drizzle": @"heavy-drizzle",
                                              @"light rain": @"light-rain",
                                              @"rain": @"rain",
                                              @"heavy right": @"heavy-rain",
                                              @"light snow": @"light-snow",
                                              @"snow": @"snow",
                                              @"heavy snow": @"heavy-snow",
                                              @"light snow grains": @"light-snow",
                                              @"snow grains": @"snow",
                                              @"heavy snow grains": @"heavy-snow",
                                              @"light ice pellets": @"light-snow",
                                              @"ice pellets": @"snow",
                                              @"heavy ice pellets": @"heavy-snow",
                                              @"light hail": @"freezing-rain",
                                              @"hail": @"freezing-rain",
                                              @"heavy hail": @"freezing-rain",
                                              @"light mist": @"mist",
                                              @"mist": @"mist",
                                              @"heavy mist": @"mist",
                                              @"light fog": @"fog",
                                              @"fog": @"fog",
                                              @"heavy fog": @"fog",
                                              @"light fog patches": @"fog",
                                              @"fog patches": @"fog",
                                              @"heavy fog patches": @"fog",
                                              @"light smoke": @"smoke",
                                              @"smoke": @"smoke",
                                              @"heavy smoke": @"smoke",
                                              @"light volcanic ash": @"fog",
                                              @"volcanic ash": @"fog",
                                              @"heavy volcanic ash": @"fog",
                                              @"light widespread dust": @"fog",
                                              @"widespread dust": @"fog",
                                              @"heavy widespread dust": @"fog",
                                              @"light sand": @"smoke",
                                              @"sand": @"smoke",
                                              @"heavy sand": @"smoke",
                                              @"light haze": @"mist",
                                              @"haze": @"mist",
                                              @"heavy haze": @"mist",
                                              @"light spray": @"light-drizzle",
                                              @"spray": @"drizzle",
                                              @"heavy spray": @"heavy-drizzle",
                                              @"light dust whirls": @"smoke",
                                              @"dust whirls": @"smoke",
                                              @"heavy dust whirls": @"tornado",
                                              @"light sandstorm": @"mist",
                                              @"sandstorm": @"mist",
                                              @"heavy sandstorm": @"tornado",
                                              @"light low drifting snow": @"light-snow",
                                              @"low drifting snow": @"snow",
                                              @"heavy low drifting snow": @"heavy-snow",
                                              @"light low drifting widespread dust": @"mist",
                                              @"low drifting widespread dust": @"mist",
                                              @"heavy low drifting widespread dust": @"mist",
                                              @"light low drifting sand": @"mist",
                                              @"low drifting sand": @"mist",
                                              @"heavy low drifting sand": @"mist",
                                              @"light blowing snow": @"light-snow",
                                              @"blowing snow": @"snow",
                                              @"heavy blowing snow": @"heavy-snow",
                                              @"light blowing widespread dust": @"mist",
                                              @"blowing widespread dust": @"mist",
                                              @"heavy blowing widespread dust": @"tornado",
                                              @"light blowing sand": @"smoke",
                                              @"blowing sand": @"smoke",
                                              @"heavy blowing sand": @"tornado",
                                              @"light rain mist": @"light-drizzle-rain",
                                              @"rain mist": @"drizzle-rain",
                                              @"heavy rain mist": @"heavy-drizzle-rain",
                                              @"light rain showers": @"shower-rain",
                                              @"rain showers": @"shower-rain",
                                              @"heavy rain showers": @"shower-rain",
                                              @"light snow showers": @"shower-snow",
                                              @"snow showers": @"shower-snow",
                                              @"heavy snow showers": @"shower-snow",
                                              @"light snow blowing snow mist": @"mist",
                                              @"snow blowing snow mist": @"mist",
                                              @"heavy snow blowing snow mist": @"mist",
                                              @"light ice pellet showers": @"shower-snow",
                                              @"ice pellet showers": @"shower-snow",
                                              @"heavy ice pellet showers": @"shower-snow",
                                              @"light hail showers": @"freezing-rain",
                                              @"hail showers": @"freezing-rain",
                                              @"heavy hail showers": @"freezing-rain",
                                              @"light small hail showers": @"freezing-rain",
                                              @"small hail showers": @"freezing-rain",
                                              @"heavy small hail showers": @"freezing-rain",
                                              @"light thunderstorm": @"light-thunderstorm",
                                              @"thunderstorm": @"light-thunderstorm",
                                              @"heavy thunderstorm": @"light-thunderstorm",
                                              @"light thunderstorms and rain": @"thunderstorm-light-rain",
                                              @"thunderstorms and rain": @"thunderstorm-rain",
                                              @"heavy thunderstorms and rain": @"thunderstorm-heavy-rain",
                                              @"light thunderstorms and ice pellets": @"thunderstorm-light-rain",
                                              @"thunderstorms and ice pellets": @"thunderstorm-rain",
                                              @"heavy thunderstorms and ice pellets": @"thunderstorm-heavy-rain",
                                              @"light thunderstorms with hail": @"thunderstorm-light-rain",
                                              @"thunderstorms with hail": @"thunderstorm-rain",
                                              @"heavy thunderstorms with hail": @"thunderstorm-heavy-rain",
                                              @"light thunderstorms with small hail": @"thunderstorm-light-rain",
                                              @"thunderstorms with small hail": @"thunderstorm-rain",
                                              @"heavy thunderstorms with small hail": @"thunderstorm-heavy-rain",
                                              @"light freezing drizzle": @"light-drizzle",
                                              @"freezing drizzle": @"drizzle",
                                              @"heavy freezing drizzle": @"heavy-drizzle",
                                              @"light freezing rain": @"freezing-rain",
                                              @"freezing rain": @"freezing-rain",
                                              @"heavy freezing rain": @"freezing-rain",
                                              @"light freezing fog": @"fog",
                                              @"freezing fog": @"fog",
                                              @"heavy freezing fog": @"fog",
                                              @"patches of fog": @"fog",
                                              @"shallow fog": @"fog",
                                              @"partial fog": @"fog",
                                              @"overcast": @"broken-clouds",
                                              @"clear": @"clear-sky",
                                              @"partly cloudy": @"few-clouds",
                                              @"mostly cloudy": @"few-clouds",
                                              @"scattered clouds": @"scattered-clouds",
                                              @"small hail": @"freezing-rain",
                                              @"squalls": @"broken-clouds",
                                              @"funnel cloud": @"broken-clouds",
                                              @"unknown precipitation": @"rain",
                                              @"unknown": @"scattered-clouds"
                                              };
    
    return wundergroundCodes[code];
}

@end

@implementation Wunderground_Data_ProviderPlugIn (Execution)

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
    
    if ([self.inputWundergroundAPIKey isEqualToString:@""]) {
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
    
    NSString *urlString = [NSString stringWithFormat:@"http://api.wunderground.com/api/%@/hourly/q/%0.2f,%0.2f.json",
                           self.inputWundergroundAPIKey,
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
    
    if ([json[@"response"] objectForKey:@"error"]) {
        NSLog(@"Wunderground: %@", json[@"response"][@"error"]);
        return YES;
    }
    
    NSDictionary *forecast;
    
    for (forecast in json[@"hourly_forecast"]) {
        
        NSDate *forecastDate = [NSDate dateWithTimeIntervalSince1970:
                                [forecast[@"FCTTIME"][@"epoch"] doubleValue]];
        
        if ([forecastDate compare:inDate] == NSOrderedDescending || [forecastDate compare:inDate] == NSOrderedSame)
            break;
    }
    
    self.outputTemperature = [forecast[@"temp"][@"metric"] doubleValue];
    
    self.outputWindDirection = [forecast[@"wdir"][@"degrees"] doubleValue];
    self.outputWindStrength = [forecast[@"wspd"][@"metric"] doubleValue];
    
    self.outputIcon = [self weatherIconForCondition: forecast[@"condition"] ];
    
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
