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

void help() {
    NSLog(@"Weather Automation Tool v1.0");
    NSLog(@"Author: Oleksii Osynovskyi (hello@osynovskyy.com)");
    NSLog(@"-------------------------------------------------");
    NSLog(@"./Weather-Automator --comp <compname.qtz> --in <0.0> --out <10.0> --data <sector1.qtz> .. <sectorN.qtz> --time <9:00> <12:00> .. <23:00> --ingest <PATH/TO/INGEST/> [--audio <audiofile.aif>]");
    
    exit(-1);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        
        NSLog(@"%@", arguments);
        
        NSString *compositionPath;
        NSString *audioPath;
        NSTimeInterval inPoint = 0, outPoint = 0;
        NSString *ingestPath;
        
        NSDate *startTime;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSMutableArray *outputTimes = [[NSMutableArray alloc] init];//@[@"09:00", @"12:00", @"15:00", @"18:00", @"21:00"];
        NSMutableArray *dataProviders = [[NSMutableArray alloc] init];
        int dataProviderIndex = 0;
        
        if ([arguments count] > 1) {
            
            //comp arguments
            
            NSUInteger i = [arguments indexOfObject:@"--comp"];
            if (i == NSNotFound)
                help();
            
            if (i+1 <= [arguments count])
                compositionPath = arguments[i+1];
            else
                help();
            
            //comp arguments
            
            i = [arguments indexOfObject:@"--ingest"];
            if (i == NSNotFound)
                help();
            
            if (i+1 <= [arguments count])
                ingestPath = arguments[i+1];
            else
                help();
            
            //inPoint argument
            
            i = [arguments indexOfObject:@"--in"];
            
            if (i == NSNotFound)
                help();
            
            if (i+1 <= [arguments count])
                inPoint = [arguments[i+1] doubleValue];
            else
                help();
            
            //ouPoint argument
            
            i = [arguments indexOfObject:@"--out"];
            
            if (i == NSNotFound)
                help();
            
            if (i+1 <= [arguments count])
                outPoint = [arguments[i+1] doubleValue];
            else
                help();
            
            //finding data providers
            
            i = [arguments indexOfObject:@"--data"];
            
            if (i == NSNotFound)
                help();
            
            if (i+1 <= [arguments count]) {
                NSUInteger j = [arguments count];
                
                for (NSUInteger x = i+1; x < j; x++) {
                    NSRange check = [arguments[x] rangeOfString:@"--"];
                    if (check.location == 0)
                        break;
                    else
                        [dataProviders addObject:arguments[x]];
                }
            }
            else
                help();
            
            //finding time
            
            i = [arguments indexOfObject:@"--time"];
            
            if (i == NSNotFound)
                help();
            
            if (i+1 <= [arguments count]) {
                NSUInteger j = [arguments count];
                
                for (NSUInteger x = i+1; x < j; x++) {
                    NSRange check = [arguments[x] rangeOfString:@"--"];
                    if (check.location == 0)
                        break;
                    else
                        [outputTimes addObject:arguments[x]];
                }
            }
            else
                help();

            //audio if necessary
            
            i = [arguments indexOfObject:@"--audio"];
            if (i != NSNotFound) {
                if (i+1 <= [arguments count])
                    audioPath = arguments[i+1];
            }
        } else
            help();
        
        NSOperationQueue *mainQueue = [[NSOperationQueue alloc] init];
        
        NSString *compostionPath = [compositionPath stringByStandardizingPath];
        QuartzOfflineRenderer *renderer;
        
        NSURL *audioUrl;
        
        if (audioPath)
             audioUrl = [NSURL fileURLWithPath: audioPath];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        
        NSDateFormatter *fullDateFormatter = [[NSDateFormatter alloc] init];
        fullDateFormatter.dateFormat = @"yyyy-MM-dd hh:mm";
        
        NSDateFormatter *filenameDateFormatter = [[NSDateFormatter alloc] init];
        filenameDateFormatter.dateFormat = @"ddMMyy";
        
        NSDateFormatter *yearDateFromatter = [[NSDateFormatter alloc] init];
        yearDateFromatter.dateFormat = @"yyyy";
        
        NSDate *nowDate = [[NSDate alloc] init];
        
        NSDateComponents *offsetDateComponets = [[NSDateComponents alloc] init];
        [offsetDateComponets setDay:1];
        
        NSCalendar *gregorian = [NSCalendar calendarWithIdentifier: NSCalendarIdentifierGregorian];
        
        NSDate *tomorrowDate = [gregorian dateByAddingComponents:offsetDateComponets toDate:nowDate options:0];
        
        for (NSString *time in outputTimes) {
            
            NSDate *renderDate;
            
            if ([time hasPrefix:@"t"]) {
                NSString *tomorrowTime = [time stringByReplacingOccurrencesOfString:@"t" withString:@""];
                renderDate = [fullDateFormatter dateFromString: [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:tomorrowDate], tomorrowTime] ];
            } else
                renderDate = [fullDateFormatter dateFromString: [NSString stringWithFormat:@"%@ %@", [dateFormatter stringFromDate:nowDate], time] ];
            
            if ([nowDate compare:renderDate] != NSOrderedDescending) {
                
                int result;
                
                do {
                    
                    startTime = [[NSDate alloc] init];
                    
                    NSDictionary *parameters = @{@"Date_And_Time": [fullDateFormatter stringFromDate: renderDate],
                                                 @"Sector_Composition": dataProviders[dataProviderIndex],
                                                 @"Copyright": [NSString stringWithFormat:@"©%@ ТОВ \"УНІАН ТВ\"", [yearDateFromatter stringFromDate:nowDate] ],
                                                 @"Opening": [time hasPrefix:@"t"] ? @"tomorrow" : @"today" };
                    
                    renderer = [[QuartzOfflineRenderer alloc] initWithCompositionPath:compostionPath
                                                                            inputKeys:parameters
                                                                           pixelsWide:RENDER_WIDTH
                                                                          pixelsHight:RENDER_HEIGHT];
                    
                    NSString *dateString = [NSString stringWithFormat:@"%@UPOGODA-%lu", [filenameDateFormatter stringFromDate:nowDate], (unsigned long)[outputTimes indexOfObject:time]+1];
                    NSString *filename = [NSString stringWithFormat:@"%@.mov", dateString];
                    
                    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), filename]];
                    
                    if (renderer) {
                        
                        if ([renderer setupOutputWithURL: url inPoint:inPoint outPoint:outPoint] && (audioUrl!=nil ? [renderer addAudio:audioUrl] : YES) ) { //
                            
                            [mainQueue addOperations: @[renderer] waitUntilFinished:YES];
                            
                        } else {
                            NSLog(@"ERROR: Failed to render: %@", url);
                        }
                    } else {
                        NSLog(@"ERROR: QuartzOfflineRenderer couldn't create");
                        result = -1;
                    }
                    
                    result = isOK(startTime);
                    
                    if (result == -1) { //looking for another data provider
                        
                        dataProviderIndex ++;
                        if (dataProviderIndex >= [dataProviders count])
                            dataProviderIndex = 0;
                        
                    } else { //copy file to ingest
                        
                        NSError *error;
                        
                        NSURL *urlInjest = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", ingestPath, filename]];
                        
                        if ([fileManager fileExistsAtPath:[urlInjest path]])
                            [fileManager removeItemAtURL:urlInjest error:&error];
                        
                        if ([fileManager moveItemAtURL:url toURL:urlInjest error:&error]) {
                            NSLog(@"OK: Successfully moved to injest %@", urlInjest);
                        } else {
                            NSLog(@"ERROR: Failed move to injest %@ with error code: %ld", urlInjest, [error code]);
                        }
                        
                    }
                    
                } while (result == -1); //repeat until success
            }
        }
    }
    
    return 0;
}
