/***************************************************************************
                                GNUStepOutput.h
                          -------------------
    begin                : Sat Jan 18 01:31:16 CST 2003
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

@class GNUstepOutput, NSString, NSColor;

#include <Foundation/NSObject.h>
#include <Foundation/NSBundle.h>

NSString *GNUstepOutputLowercase(NSString *aString);
NSString *GNUstepOutputIdentificationForController(id controller);
BOOL GNUstepOutputCompare(NSString *aString, NSString *aString2);
NSColor *GNUstepOutputColor(NSColor *aColor);

extern NSString *GNUstepOutputPersonalBracketColor;
extern NSString *GNUstepOutputOtherBracketColor;
extern NSString *GNUstepOutputTextColor;
extern NSString *GNUstepOutputBackgroundColor;
extern NSString *GNUstepOutputServerList;
extern NSString *GNUstepOutputFontName;
extern NSString *GNUstepOutputFontSize;

extern GNUstepOutput *_GS_;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [GNUstepOutput class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

#ifndef GNUSTEP_OUTPUT_H
#define GNUSTEP_OUTPUT_H

#include <Foundation/NSMapTable.h>
#include "TalkSoupBundles/TalkSoup.h"

@class NSAttributedString, NSArray, NSAttributedString, NSMutableDictionary;
@class NSDictionary, ConnectionController, PreferencesController;
@class TopicInspectorController, ServerListController;

@interface GNUstepOutput : NSObject
	{
		NSMutableDictionary *pendingIdentToConnectionController;
		NSMapTable *connectionToConnectionController;
		NSMutableArray *connectionControllers;
		NSMutableArray *serverLists;		
		NSDictionary *defaultDefaults;
		PreferencesController *prefs;
		TopicInspectorController *topic;
		BOOL terminating;
	}
- setDefaultsObject: aObject forKey: aKey;

- (id)defaultsObjectForKey: aKey;

- (id)defaultDefaultsForKey: aKey;

- (id)connectionToConnectionController: (id)aObject;

- waitingForConnection: (NSString *)aIdent onConnectionController: (id)controller;

- addConnectionController: (ConnectionController *)aCont;
- removeConnectionController: (ConnectionController *)aCont;
- (NSArray *)connectionControllers;

- addServerList: (ServerListController *)aServer;
- removeServerList: (ServerListController *)aServer;

- (TopicInspectorController *)topicInspectorController;
- (void)run;
@end

#endif
