//
//  Weather_SectorPlugIn.h
//  Weather Sector
//
//  Created by Oleksii Osynovskyi on 6/9/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#import <Quartz/Quartz.h>
#include <Accelerate/Accelerate.h>

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@interface WeatherSectorPlugIn : QCPlugIn {
    id _placeHolderProvider;
}

// Declare here the properties to be used as input and output ports for the plug-in e.g.
//@property double inputFoo;
//@property (copy) NSString* outputBar;

@property (assign) BOOL inputAnimationEnable;
@property (assign) double inputInPoint;
@property (assign) double inputOutPoint;
@property (assign) double inputAnimationDuration;

@property (assign) NSString *inputIcon;
@property (assign) double inputRadius;
@property (assign) double inputTemp;
@property (assign) double inputWindDirection;
@property (assign) double inputWindStrength;
@property (assign) CGColorRef inputWindColor;
@property (assign) CGColorRef inputBackgroundColor;

@property (copy) id<QCPlugInOutputImageProvider> outputSector;

@end
