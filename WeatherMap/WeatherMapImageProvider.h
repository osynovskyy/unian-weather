//
//  WeatheMapImageProvider.h
//  Weather Sector
//
//  Created by Oleksii Osynovskyi on 6/18/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

#include <Accelerate/Accelerate.h>
#include <Quartz/Quartz.h>

@interface WeatherMapImageProvider : NSObject <QCPlugInOutputImageProvider> {
    vImage_Buffer bufferMap, bufferOutline;
    
    vImage_Buffer renderBuffer;
}

@property double defocus;
@property id<QCPlugInInputImageSource> overImage;

@property BOOL needUpdate;

- (void)clean;

@end
