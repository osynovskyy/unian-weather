//
//  WeatherCodes.m
//  Weather Sector
//
//  Created by Oleksii Osynovskyi on 6/15/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#import "WeatherCodes.h"

@implementation WeatherCodes

+ (NSDictionary *)codes {
    static NSDictionary *codes = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        codes = @{
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
                  @"622": @"heavy-snow", //heavy shower snow
                  @"701": @"mist",
                  @"711": @"smoke",
                  @"721": @"mist", //haze
                  @"731": @"smoke", //sand dsut whirls
                  @"741": @"fog",
                  @"751": @"smoke", //sand
                  @"761": @"fog", //dust
                  @"762": @"fog", //volcanic ash
                  @"772": @"fog", //squalls
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
    });
    
    return codes;
}

@end
