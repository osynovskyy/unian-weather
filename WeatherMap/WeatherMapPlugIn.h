//
//  WeatherMapPlugIn.h
//  WeatherMap
//
//  Created by Oleksii Osynovskyi on 6/18/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#import <Quartz/Quartz.h>

@interface WeatherMapPlugIn : QCPlugIn

// Declare here the properties to be used as input and output ports for the plug-in e.g.
//@property double inputFoo;
//@property (copy) NSString* outputBar;

@property (assign) id<QCPlugInInputImageSource> inputOverImage;

@property (assign) double inputDefocus;

@property (copy) id<QCPlugInOutputImageProvider> outputMap;

@end
