/*****************************************************************************
 *  Copyright (c) 2011 Meta Watch Ltd.                                       *
 *  www.MetaWatch.org                                                        *
 *                                                                           *
 =============================================================================
 *                                                                           *
 *  Licensed under the Apache License, Version 2.0 (the "License");          *
 *  you may not use this file except in compliance with the License.         *
 *  You may obtain a copy of the License at                                  *
 *                                                                           *
 *    http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                           *
 *  Unless required by applicable law or agreed to in writing, software      *
 *  distributed under the License is distributed on an "AS IS" BASIS,        *
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 *  See the License for the specific language governing permissions and      *
 *  limitations under the License.                                           *
 *                                                                           *
 *****************************************************************************/

//
//  WidgetRss.m
//  MWM
//
//  Created by Siqi Hao on 4/20/12.
//  Copyright (c) 2012 Meta Watch. All rights reserved.
//

// http://feeds.bbci.co.uk/news/rss.xml

#import "WidgetRss.h"
#import "MWRssMonitor.h"

@implementation WidgetRss

@synthesize preview, updateIntvl, updatedTimestamp, settingView, widgetSize, widgetID, delegate, previewRef;

@synthesize received, geoLocationEnabled, updatedTime, currentRssFeed, widgetName, rssUpdateIntervalInMins;

static NSInteger widget = 10004;
static CGFloat widgetWidth = 96;
static CGFloat widgetHeight = 32;

+ (CGSize) getWidgetSize {
    return CGSizeMake(widgetWidth, widgetHeight);
}

- (id)init
{
    self = [super init];
    if (self) {
        widgetSize = CGSizeMake(widgetWidth, widgetHeight);
        preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, widgetWidth, widgetHeight)];
        widgetID = widget;
        widgetName = @"Rss";
        received = NO;
        currentRssFeed = @"http://feeds.bbci.co.uk/news/rss.xml";
        updateIntvl = 3600;
        updatedTimestamp = 0;
        
        [[MWRssMonitor sharedMonitor] setRssFeed:currentRssFeed];
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSDictionary *dataDict = [prefs valueForKey:[NSString stringWithFormat:@"%d", widgetID]];
        if (dataDict == nil) {
            [self saveData];
        } else {
            self.currentRssFeed = [dataDict valueForKey:@"rssFeed"];
            updateIntvl = [[dataDict valueForKey:@"updateInterval"] integerValue];
            NSLog(@"currentRssFeed: %@", currentRssFeed);
            [[MWRssMonitor sharedMonitor] setRssFeed:currentRssFeed];
        }
        
        // Setting
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"WidgetRssSettingView" owner:nil options:nil];
        self.settingView = [topLevelObjects objectAtIndex:0];
        self.settingView.alpha = 0;
        
        [(UITextField*)[settingView viewWithTag:3002] setDelegate:self];
        [(UITextField*)[settingView viewWithTag:3002] setText:currentRssFeed];
        
        [(UIButton*)[settingView viewWithTag:3003] addTarget:self action:@selector(updateBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
        if (updateIntvl == 30*60) {
            [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Half an Hour" forState:UIControlStateNormal];
        } else if (updateIntvl == 3600) {
            [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Hourly" forState:UIControlStateNormal];
        } else if (updateIntvl == 2*3600) {
            [(UIButton*)[settingView viewWithTag:3003] setTitle:@"2 Hours" forState:UIControlStateNormal];
        } else if (updateIntvl == 6*3600) {
            [(UIButton*)[settingView viewWithTag:3003] setTitle:@"6 Hours" forState:UIControlStateNormal];
        } else if (updateIntvl == 24*3600) {
            [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Daily" forState:UIControlStateNormal];
        } else {
            [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Hourly" forState:UIControlStateNormal];
            updateIntvl = 3600;
            [self saveData];
        }
        
    }
    return self;
}

- (void) saveData {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:currentRssFeed forKey:@"rssFeed"];
    [dataDict setObject:[NSNumber numberWithInteger:updateIntvl] forKey:@"updateInterval"];
    
    [prefs setObject:dataDict forKey:[NSString stringWithFormat:@"%d", widgetID]];
    
    //NSLog(@"RssData: %@", [dataDict description]);
    
    [prefs synchronize];
}

- (void) prepareToUpdate {
    [delegate widgetViewCreated:self];
}

- (void) stopUpdate {
}

- (int)itemCount:(NSArray*)rssArray {
    int itemCount = 0;
    
    for (MWElementRss* rss in rssArray) {
        NSMutableArray* channelArray = rss.channelArray;
        for (MWElementChannel* channel in channelArray) {
            NSMutableArray* itemArray = channel.itemArray;
            itemCount += itemArray.count;
        }
    }
    return itemCount;
}

- (void) update:(NSInteger)timestamp {
    if (updateIntvl < 0 && timestamp > 0) {
        return;
    }
    if (timestamp < 0 || timestamp - updatedTimestamp >= updateIntvl) {
        updatedTimestamp = timestamp;
        NSArray* rssArray = [[MWRssMonitor sharedMonitor] currentRss];
        if ([self itemCount:rssArray] > 0) {
            received = YES;
            [self drawRss:rssArray];
        } else {
            [self drawNullRss];
        }
        
        [delegate widget:self updatedWithError:nil];
    }
    if (timestamp < 0) {
        updatedTimestamp = (NSInteger)[NSDate timeIntervalSinceReferenceDate];
    }

}

- (void) drawNullRss {
    UIFont *font = [UIFont fontWithName:@"MetaWatch Small caps 8pt" size:8];   
    //UIFont *largeFont = [UIFont fontWithName:@"MetaWatch Large 16pt" size:16];
    CGSize size  = CGSizeMake(widgetWidth, widgetHeight);
    
    UIGraphicsBeginImageContextWithOptions(size,NO,1.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //CGContextSetFillColorWithColor(ctx, [[UIColor clearColor]CGColor]);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, widgetWidth, widgetHeight));
    
    CGContextSetFillColorWithColor(ctx, [[UIColor blackColor]CGColor]);
    
    /*
     Draw the Rss
     */
    [@"No Rss Data" drawInRect:CGRectMake(0, 12, widgetWidth, widgetHeight) withFont:font lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentCenter];
    
    previewRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();   
    
    for (UIView *view in self.preview.subviews) {
        [view removeFromSuperview];
    }
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = 7001;
    imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [self.preview addSubview:imageView];
}

- (void) drawRss:(NSArray*)rssArray {
    int itemCount = 0;
    int maxItems = 3;
    
    UIFont *font = [UIFont fontWithName:@"MetaWatch Small caps 8pt" size:8];   
    CGSize size  = CGSizeMake(widgetWidth, widgetHeight);
    
    UIGraphicsBeginImageContextWithOptions(size,NO,1.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    //CGContextSetFillColorWithColor(ctx, [[UIColor clearColor]CGColor]);
    
    // Fill background as white
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, widgetWidth, widgetHeight));
    
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    NSInteger currentHeight = 4;

    for (MWElementRss* rss in rssArray) {
        NSMutableArray* channelArray = rss.channelArray;
        for (MWElementChannel* channel in channelArray) {
            NSMutableArray* itemArray = channel.itemArray;
            for (MWElementItem* item in itemArray) {
                NSString* drawingString = item.p_title;
                [drawingString drawInRect:CGRectMake(3, currentHeight, 90, 5) withFont:font lineBreakMode:UILineBreakModeCharacterWrap alignment:UITextAlignmentLeft];
                currentHeight = currentHeight + 9; // font is 5
                itemCount++;
                if (itemCount >= maxItems)
                    break;            
            }
            if (itemCount >= maxItems)
                break;            
        }
        if (itemCount >= maxItems)
            break;            
    }
    
    // transfer image
    previewRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();   
    
    for (UIView *view in self.preview.subviews) {
        [view removeFromSuperview];
    }
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = 7001;
    imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [self.preview addSubview:imageView];
    
    [delegate widget:self updatedWithError:nil];
    
}

- (void) textFieldDidBeginEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setCenter:CGPointMake(160, 20)];
    [UIView commitAnimations];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setCenter:CGPointMake(160, 240)];
    [UIView commitAnimations];
    [textField resignFirstResponder];
    
    if ([currentRssFeed isEqualToString:textField.text]) {
        return NO;
    }
    self.currentRssFeed = textField.text;
    if (currentRssFeed.length == 0) {
        currentRssFeed = @"http://feeds.bbci.co.uk/news/rss.xml";
    }
    [[MWRssMonitor sharedMonitor] setRssFeed:currentRssFeed];
    
    [self saveData];
    
    [self update:-1];
    
    return NO;
}

- (void) updateBtnPressed:(id)sender {
    [[[UIActionSheet alloc] initWithTitle:@"Select update interval" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Half an Hour", @"Hourly", @"2 Hours", @"6 Hours", @"Daily", nil] showInView:self.settingView];
    
}

- (void) actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Half an Hour" forState:UIControlStateNormal];
        updateIntvl = 30*60;
    } else if (buttonIndex == 1) {
        [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Hourly" forState:UIControlStateNormal];
        updateIntvl = 3600;
    } else if (buttonIndex == 2) {
        [(UIButton*)[settingView viewWithTag:3003] setTitle:@"2 Hours" forState:UIControlStateNormal];
        updateIntvl = 2*3600;
    } else if (buttonIndex == 3) {
        [(UIButton*)[settingView viewWithTag:3003] setTitle:@"6 Hours" forState:UIControlStateNormal];
        updateIntvl = 6*3600;
    } else if (buttonIndex == 4) {
        [(UIButton*)[settingView viewWithTag:3003] setTitle:@"Daily" forState:UIControlStateNormal];
        updateIntvl = 24*3600;
    }
    [self saveData];
}

- (void) dealloc {
    [self stopUpdate];
    [delegate widgetViewShoudRemove:self];
}

@end
