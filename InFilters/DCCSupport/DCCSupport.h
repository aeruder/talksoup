/***************************************************************************
                             DCCSupport.h
                          -------------------
    begin                : Wed Jul 2 18:58:30 CDT 2003
    copyright            : (C) 2003 by Andy Ruder
    email                : aeruder@yahoo.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

@class DCCSupport;

@class NSBundle, NSString;

extern NSString *DCCDownloadDirectory;
extern NSString *DCCCompletedDirectory;
extern NSString *DCCPortRange;
extern NSString *DCCGetTimeout;
extern NSString *DCCSendTimeout;
extern NSString *DCCDefault;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [DCCSupport class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

#ifndef DCCSUPPORT_H
#define DCCSUPPORT_H

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@class NSAttributedString, NSMutableArray, NSDictionary;

@interface DCCSupport : NSObject
	{
		NSMapTable *connectionMap;
		id controller;
	}

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
@end

@interface DCCSupport (PrivateSupport)
+ (NSDictionary *)defaultSettings;
+ (id)defaultsObjectForKey: aKey;
+ (id)defaultDefaultsForKey: aKey;
+ (void)setDefaultsObject: aObject forKey: aKey;

- (void)startedReceive: dcc onConnection: aConnection;
- (void)finishedReceive: dcc onConnection: aConnection;
- (void)startedSend: dcc onConnection: aConnection;
- (void)finishedSend: dcc onConnection: aConnection;
- (NSMutableArray *)getConnectionTable: aConnection;
@end

#endif
