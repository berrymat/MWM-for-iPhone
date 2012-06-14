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
//  KARssMonitor.h
//  MWManager
//
//  Created by Kai Aras on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWElementRss, MWElementChannel, MWElementItem;

@interface MWRssMonitor : NSObject<NSXMLParserDelegate> {
    NSString* _rssFeed;
    NSMutableArray* _context;
    NSMutableArray* _rssArray;
}

+(MWRssMonitor*) sharedMonitor;

-(NSMutableArray*)currentRss;

@property (nonatomic, retain) NSString *rssFeed;
@property (nonatomic, retain) NSMutableArray *context;
@property (nonatomic, retain) NSMutableArray* rssArray;

@property (nonatomic, readonly) id currentElement;

- (MWElementRss*)add_rss;

@end

@interface MWElementRss : NSObject {
    NSString* _version;
    NSMutableArray* _channelArray;
}

@property (nonatomic, retain) NSString* p_version;
@property (nonatomic, retain) NSMutableArray* channelArray;

- (MWElementChannel*)add_channel;

@end

@interface MWElementChannel : NSObject {
    NSString* _title;
    NSString* _description;
    NSString* _link;
    NSString* _lastBuildDate;
    NSString* _pubDate;
    NSString* _ttl;
    
    NSMutableArray* _itemArray;
}

@property (nonatomic, retain) NSString* p_title;
@property (nonatomic, retain) NSString* p_description;
@property (nonatomic, retain) NSString* p_link;
@property (nonatomic, retain) NSString* p_lastBuildDate;
@property (nonatomic, retain) NSString* p_pubDate;
@property (nonatomic, retain) NSString* p_ttl;
@property (nonatomic, retain) NSMutableArray* itemArray;

- (MWElementItem*)add_item;

@end

@interface MWElementItem : NSObject {
    NSString* _title;
    NSString* _description;
    NSString* _link;
    NSString* _guid;
    NSString* _pubDate;
}

@property (nonatomic, retain) NSString* p_title;
@property (nonatomic, retain) NSString* p_description;
@property (nonatomic, retain) NSString* p_link;
@property (nonatomic, retain) NSString* p_guid;
@property (nonatomic, retain) NSString* p_pubDate;

@end

@interface MWIgnore : NSObject {
}

+ (MWIgnore*)ignore;

@end

/* This is what we are trying to parse...
 <rss version="2.0">
   <channel>
     <title>RSS Title</title>
     <description>This is an example of an RSS feed</description>
     <link>http://www.someexamplerssdomain.com/main.html</link>
     <lastBuildDate>Mon, 06 Sep 2010 00:01:00 +0000 </lastBuildDate>
     <pubDate>Mon, 06 Sep 2009 16:45:00 +0000 </pubDate>
     <ttl>1800</ttl>
 
     <item>
       <title>Example entry</title>
       <description>Here is some text containing an interesting description.</description>
       <link>http://www.wikipedia.org/</link>
       <guid>unique string per item</guid>
       <pubDate>Mon, 06 Sep 2009 16:45:00 +0000 </pubDate>
     </item>
   </channel>
 </rss>
*/
