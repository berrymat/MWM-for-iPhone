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
//  KARssMonitor.m
//  MWManager
//
//  Created by Kai Aras on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MWRssMonitor.h"

@implementation MWRssMonitor
@synthesize rssFeed=_rssFeed, context=_context, rssArray=_rssArray;

static MWRssMonitor *sharedMonitor;

#pragma mark - Singleton

+(MWRssMonitor *) sharedMonitor {
    if (sharedMonitor == nil) {
        sharedMonitor = [[super allocWithZone:NULL]init];
    }
    return sharedMonitor;    
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.rssFeed = @"http://feeds.bbci.co.uk/news/rss.xml";
    }
    
    return self;
}

-(NSMutableArray*)currentRss {
    NSURL *url =[NSURL URLWithString:self.rssFeed];
    
    if (url == nil) {
        NSLog(@"invalid url");
        return nil;
    }
    
    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    
    if (data == nil || error != nil) {
        NSLog(@"no rss data");
        return nil;
    }
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"dataString: %@", dataString);
    [dataString release];
    
    self.context = [NSMutableArray arrayWithObject:self];
    self.rssArray = nil;
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setShouldProcessNamespaces:YES];
    [parser setShouldResolveExternalEntities:YES];
    [parser setShouldReportNamespacePrefixes:YES];
    [parser setDelegate:self];
    [parser parse];
    [parser release];
    
    [self.context removeLastObject];
    
    /*
    NSInteger lowInF = [[rssDict valueForKey:@"low"] integerValue];
    [rssDict setValue:[NSString stringWithFormat:@"%d", ((lowInF - 32) *5/9)] forKey:@"low_c"];
    NSInteger highInF = [[rssDict valueForKey:@"high"] integerValue];
    [rssDict setValue:[NSString stringWithFormat:@"%d", ((highInF - 32) *5/9)] forKey:@"high_c"];
    */
    //NSLog(@"rss: %@", self.rssDict);
    return self.rssArray;
}

- (MWElementRss*)add_rss {
    if (_rssArray == nil)
        self.rssArray = [NSMutableArray array];
    MWElementRss* rss = [[[MWElementRss alloc] init] autorelease];
    [_rssArray addObject:rss];
    return rss;
}

- (id)currentElement {
    return [self.context lastObject];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)eName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    //  NSLog(@"element: %@ %@",elementName, attributeDict);

    SEL addSelector = NSSelectorFromString([NSString stringWithFormat:@"add_%@", eName]);
    if ([self.currentElement respondsToSelector:addSelector]) {
        id child = [self.currentElement performSelector:addSelector withObject:nil];
        [self.context addObject:child];
 
        for (NSString* k in attributeDict) {
            NSString* key = [NSString stringWithFormat:@"p_%@", k];
            SEL valueSelector = NSSelectorFromString(key);
            if ([child respondsToSelector:valueSelector]) {
                id value = [attributeDict objectForKey:key];
                [child setValue:value forKey:key];
            }
        }        
    } else {
        NSString* elementName = [NSString stringWithFormat:@"p_%@", eName];
        SEL selectorName = NSSelectorFromString(elementName);
        if ([self.currentElement respondsToSelector:selectorName]) {
            [self.context addObject:[NSMutableString string]];
        }
        else {
            [self.context addObject:[MWIgnore ignore]];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ([[self.currentElement class] isSubclassOfClass:[NSMutableString class]]) {
        NSMutableString* stringValue = (NSMutableString*)self.currentElement;
        [stringValue appendString:string];     
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)eName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    id child = [self.currentElement retain];
    [self.context removeLastObject];
        
    NSString* elementName = [NSString stringWithFormat:@"p_%@", eName];
    SEL selectorName = NSSelectorFromString(elementName);
    if ([self.currentElement respondsToSelector:selectorName]) {
        [self.currentElement setValue:child forKey:elementName];
    }
    
    [child release];
}

- (void)dealloc {
    [_rssFeed release];
    [_context release];
    [_rssArray release];
    
    [super dealloc];
}

@end

@implementation MWElementRss

@synthesize p_version=_version, channelArray=_channelArray;

- (MWElementChannel*)add_channel {
    if (_channelArray == nil)
        self.channelArray = [NSMutableArray array];
    MWElementChannel* channel = [[[MWElementChannel alloc] init] autorelease];
    [_channelArray addObject:channel];
    return channel;
}

- (void)dealloc {
    [_version release];
    [_channelArray release];
    
    [super dealloc];
}

@end

@implementation MWElementChannel

@synthesize p_title=_title, p_description=_description, p_link=_link, p_lastBuildDate=_lastBuildDate, p_pubDate=_pubDate, p_ttl=_ttl, itemArray=_itemArray;

- (MWElementItem*)add_item {
    if (_itemArray == nil)
        self.itemArray = [NSMutableArray array];
    MWElementItem* item = [[[MWElementItem alloc] init] autorelease];
    [_itemArray addObject:item];
    return item;
}

- (void)dealloc {
    [_title release];
    [_description release];
    [_link release];
    [_lastBuildDate release];
    [_pubDate release];
    [_ttl release];
    [_itemArray release];
    
    [super dealloc];
}

@end

@implementation MWElementItem

@synthesize p_title=_title, p_description=_description, p_link=_link, p_guid=_guid, p_pubDate=_pubDate;

- (void)dealloc {
    [_title release];
    [_description release];
    [_link release];
    [_guid release];
    [_pubDate release];
    
    [super dealloc];
}

@end

@implementation MWIgnore

+ (MWIgnore*)ignore {
    return [[[MWIgnore alloc] init] autorelease];
}

@end
