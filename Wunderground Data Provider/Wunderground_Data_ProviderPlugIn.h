//
//  Wunderground_Data_ProviderPlugIn.h
//  Wunderground Data Provider
//
//  Created by Oleksii Osynovskyi on 6/22/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface Wunderground_Data_ProviderPlugIn : QCPlugIn

// Declare here the properties to be used as input and output ports for the plug-in e.g.
//@property double inputFoo;
//@property (copy) NSString* outputBar;

@property (assign) double inputLatitude;
@property (assign) double inputLongitude;

@property (assign) NSString *inputDateAndTime;

@property (assign) NSString *inputWundergroundAPIKey;

@property (assign) BOOL outputOK;

@property (assign) NSString *outputIcon;
@property (assign) double outputTemperature;
@property (assign) double outputWindDirection;
@property (assign) double outputWindStrength;

@end
