//
//  OpenWeather_Data_ProviderPlugIn.m
//  OpenWeather Data Provider
//
//  Created by Oleksii Osynovskyi on 6/19/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

// It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering
#import <OpenGL/CGLMacro.h>

#import "OpenWeather_Data_ProviderPlugIn.h"

#define	kQCPlugIn_Name				@"OpenWeather Data Provider"
#define	kQCPlugIn_Description		@"Provide data from openweathermap.org"
#define kQCPlugIn_Copyright         @"©2015 Osynovskyy.com"

@implementation OpenWeather_Data_ProviderPlugIn

// Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
//@dynamic inputFoo, outputBar;

@dynamic inputLatitude, inputLongitude; //coordinates
@dynamic inputDateAndTime;
@dynamic inputOpenWeatherAPIKey;

@dynamic outputOK;

@dynamic outputCityAndCountry;
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
    
    const NSDictionary *openWeatherCodes = @{
                                             @"200": @"thunderstorm-light-rain",
                                             @"201": @"thunderstorm-rain",
                                             @"202": @"thunderstorm-heavy-rain",
                                             @"210": @"light-thunderstorm",
                                             @"211": @"thunderstorm",
                                             @"212": @"heavy-thunderstorm",
                                             @"221": @"heavy-thunderstorm", //ragged thunderstorm
                                             @"230": @"thunderstorm-light-drizzle",
                                             @"231": @"thunderstorm-drizzle",
                                             @"232": @"thunderstorm-heavy-drizzle",
                                             @"300": @"light-drizzle",
                                             @"301": @"drizzle",
                                             @"302": @"heavy-drizzle",
                                             @"310": @"light-drizzle-rain",
                                             @"311": @"drizzle-rain",
                                             @"312": @"heavy-drizzle-rain",
                                             @"313": @"shower-drizzle", //shower rain and drizzle
                                             @"314": @"shower-drizzle", //heavy shower rain and drizzle
                                             @"321": @"shower-drizzle",
                                             @"500": @"light-rain",
                                             @"501": @"rain",
                                             @"502": @"heavy-rain",
                                             @"503": @"heavy-rain", //very heavy rain
                                             @"504": @"heavy-rain", //extreme rain
                                             @"511": @"freezing-rain",
                                             @"520": @"shower-rain", //light intensity shower rain
                                             @"521": @"shower-rain",
                                             @"522": @"shower-rain", //heavy intensity shower rain
                                             @"531": @"shower-rain", //ragged shower rain
                                             @"600": @"light-snow",
                                             @"601": @"snow",
                                             @"602": @"heavy-snow",
                                             @"611": @"snow", //sleet
                                             @"612": @"heavy-snow", //shower sleet
                                             @"615": @"light-rain-snow",
                                             @"616": @"rain-snow",
                                             @"620": @"snow", //light shower snow
                                             @"621": @"snow", //shower snow
                                             @"622": @"shower-snow", //heavy shower snow
                                             @"701": @"mist",
                                             @"711": @"smoke",
                                             @"721": @"mist", //haze
                                             @"731": @"smoke", //sand dsut whirls
                                             @"741": @"fog",
                                             @"751": @"smoke", //sand
                                             @"761": @"fog", //dust
                                             @"762": @"fog", //volcanic ash
                                             @"772": @"broken-clouds", //squalls
                                             @"781": @"tornado",
                                             @"800": @"clear-sky",
                                             @"801": @"few-clouds",
                                             @"802": @"scattered-clouds",
                                             @"803": @"broken-clouds",
                                             @"804": @"broken-clouds", //overcast clouds
                                             @"900": @"tornado",
                                             @"901": @"tornado", //tropical strom
                                             @"902": @"tornado", //hurricane
                                             @"903": @"heavy-snow", //cold
                                             @"904": @"clear-sky", //hot
                                             @"905": @"smoke", //windy
                                             @"906": @"freezing-rain" //hail
                                             };
    
    return openWeatherCodes[code];
}

@end

@implementation OpenWeather_Data_ProviderPlugIn (Execution)

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
    
    if ([self.inputOpenWeatherAPIKey isEqualToString:@""]) {
        NSLog(@"ERROR: OpenWeather API key is empty");
        return YES;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%.2f&lon=%.2f&units=metric&APPID=%@", self.inputLatitude, self.inputLongitude, self.inputOpenWeatherAPIKey]; //
   
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
    NSData *data = [[NSData alloc] init];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    if (nil == data) {
        NSLog(@"ERROR: -sendSynchronousRequest: return nill.");
        return YES;
    }
    
    NSError *error = nil;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (nil != error) {
        NSLog(@"ERROR: Error parsing Data to JSON %@", data);
        return YES;
    }
    
    if (![json[@"cod"] containsString:@"200"]) {
        NSLog(@"ERROR: OpenWeather error: %@", json[@"cod"]);
        return YES;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm";
    
    NSDate *inDate = [dateFormatter dateFromString: self.inputDateAndTime];
    
    NSDictionary *forecast;
    
    for (forecast in json[@"list"]) {
        NSDate *forecastDate = [NSDate dateWithTimeIntervalSince1970:[forecast[@"dt"] longValue]];
        
        NSComparisonResult comparsion = [forecastDate compare:inDate];
        
        if (comparsion != NSOrderedAscending)
            break;
    }
    
    self.outputCityAndCountry = [NSString stringWithFormat:@"%@, %@",
                                 json[@"city"][@"name"],
                                 json[@"city"][@"country"] ];
    
    self.outputIcon = [self weatherIconForCondition: [forecast[@"weather"][0][@"id"] stringValue] ]; //[forecast[@"weather"][0][@"id"] stringValue];
    
    self.outputTemperature = [forecast[@"main"][@"temp"] doubleValue];
    
    self.outputWindDirection = [forecast[@"wind"][@"deg"] doubleValue];
    self.outputWindStrength = [forecast[@"wind"][@"speed"] doubleValue];
    
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
