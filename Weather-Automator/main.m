//
//  main.m
//  Weather-Automator
//
//  Created by Oleksii Osynovskyi on 6/25/15.
//  Copyright (c) 2015 Oleksii Osynovskyi. All rights reserved.
//

@import Foundation;
@import Quartz;
@import AVFoundation;

#include <asl.h>

#define RENDER_WIDTH    788
#define RENDER_HEIGHT   576

#define FROM 0
#define TO 37

#define INJEST @"/Users/oleksii-osynovskyi/"

#include "QuartzOfflineRenderer.h"

int isOK(NSDate *time) {
    
    int result = 1;
    
    NSMutableDictionary *consoleLog = [NSMutableDictionary dictionary];
    
    aslclient client = asl_open(NULL, NULL, ASL_OPT_NO_DELAY);
    
    aslmsg query = asl_new(ASL_TYPE_QUERY);
    
    NSString *process_id = [NSString stringWithFormat:@"%d", getpid()];
    
    asl_set_query(query, ASL_KEY_PID, [process_id cStringUsingEncoding:NSMacOSRomanStringEncoding], ASL_QUERY_OP_EQUAL);
    asl_set_query(query, ASL_KEY_MSG, "ERROR:", ASL_QUERY_OP_PREFIX);
    
    NSString *stringTime = [NSString stringWithFormat:@"%.0f", [time timeIntervalSince1970]];
    
    asl_set_query(query, ASL_KEY_TIME, [stringTime cStringUsingEncoding:NSMacOSRomanStringEncoding], ASL_QUERY_OP_GREATER_EQUAL);
    
    aslresponse response = asl_search(client, query);
    
    asl_free(query);
    
    aslmsg message;
    while((message = asl_next(response)))
    {
        const char *msg = asl_get(message, ASL_KEY_MSG);
        const char *msg_id = asl_get(message, ASL_KEY_MSG_ID);
        
        [consoleLog setObject:[NSString stringWithCString:msg encoding:NSUTF8StringEncoding] forKey:[NSString stringWithCString:msg_id encoding:NSUTF8StringEncoding]];
        
        result = -1;
    }
    
    asl_release(response);
    asl_close(client);
    
//    NSLog(@"%@", consoleLog);
    
    return result;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSDate *startTime;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
            
        NSArray *outputTimes = @[@"09:00", @"12:00", @"15:00", @"18:00", @"21:00", @"23:00"];
        
        NSOperationQueue *mainQueue = [[NSOperationQueue alloc] init];
        
        NSString *compostionPath = [@"openweather.qtz" stringByStandardizingPath];
        QuartzOfflineRenderer *renderer;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        
        NSDateFormatter *fullDateFormatter = [[NSDateFormatter alloc] init];
        fullDateFormatter.dateFormat = @"yyyy-MM-dd hh:mm";
        
        NSDateFormatter *filenameDateFormatter = [[NSDateFormatter alloc] init];
        filenameDateFormatter.dateFormat = @"yyyyMMdd_hh:mm";
        
        NSDate *nowDate = [[NSDate alloc] init];
        
        for (NSString *time in outputTimes) {
            
            NSDate *renderDate = [fullDateFormatter dateFromString: [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:nowDate], time] ];
            
            if ([nowDate compare:renderDate] != NSOrderedDescending) {
                
                do {
                    
                    startTime = [[NSDate alloc] init];
                    
                    NSDictionary *parameters = @{@"Date_And_Time": [fullDateFormatter stringFromDate: renderDate]};
                    
                    renderer = [[QuartzOfflineRenderer alloc] initWithCompositionPath:compostionPath
                                                                            inputKeys:parameters
                                                                           pixelsWide:RENDER_WIDTH
                                                                          pixelsHight:RENDER_HEIGHT];
                    
                    if (renderer) {
                        
                        NSString *dateString = [[filenameDateFormatter stringFromDate:renderDate] stringByReplacingOccurrencesOfString:@":" withString:@""];
                        NSString *filename = [NSString stringWithFormat:@"weather_%@.mov", dateString];
                        
                        NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), filename]];
                        
                        if ([renderer setupOutputWithURL: url inPoint:FROM outPoint:TO]) {
                            
                            renderer.completionBlock = ^{
                                
                                NSError *error;
                                
                                NSURL *urlInjest = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", INJEST, filename]];
                                
                                if ([fileManager moveItemAtURL:url toURL:urlInjest error:&error]) {
                                    NSLog(@"OK: Successfully moved to injest %@", urlInjest);
                                } else {
                                    NSLog(@"ERROR: Failed move to injest %@ with error code: %ld", urlInjest, [error code]);
                                }
                                
                            };
                            
                            [mainQueue addOperations: @[renderer] waitUntilFinished:YES];
                        } else {
                            NSLog(@"ERROR: Failed to render: %@", url);
                        }
                    } else {
                        NSLog(@"ERROR: QuartzOfflineRenderer couldn't create");
                        return -1;
                    }
                    
                } while (isOK(startTime) == -1); //repeat until success
            }
        }
    }
    return 0;
}
