/***************************************************************************
                             Ignore.h
                          -------------------
    begin                : Tue Oct 11 17:20:38 CDT 2005
    copyright            : (C) 2005 by Andrew Ruder
    email                : aeruder@ksu.edu
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

@class Ignore;

#ifndef IGNORE_H
#define IGNORE_H

#import <Foundation/NSObject.h>

@class NSBundle, NSString, NSDictionary;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [Ignore class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

extern NSString *IgnoreMaskList;
@class NSAttributedString;

@interface Ignore : NSObject
+ (NSDictionary *)defaultSettings;
+ (void)setDefaultsObject: aObject forKey: aKey;
+ (id)defaultsObjectForKey: aKey;
+ (id)defaultDefaultsForKey: aKey;
- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
@end

#endif
