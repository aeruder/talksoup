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

@class GNUstepOutput, PreferencesController, NSString, NSColor;

#import <Foundation/NSObject.h>
#import <Foundation/NSBundle.h>

NSString *StandardLowercase(NSString *aString);
NSString *IRCLowercase(NSString *aString);

// lowercase function to be used by GNUstepOutput
extern NSString *(*GNUstepOutputLowercase)(NSString *aString);

NSString *GNUstepOutputIdentificationForController(id controller);
BOOL GNUstepOutputCompare(NSString *aString, NSString *aString2);

extern GNUstepOutput *_GS_;
extern PreferencesController *_PREFS_;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [GNUstepOutput class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

#ifndef GNUSTEP_OUTPUT_H
#define GNUSTEP_OUTPUT_H

#import <Foundation/NSMapTable.h>
#import "TalkSoupBundles/TalkSoup.h"

@class NSAttributedString, NSArray, NSAttributedString, NSMutableDictionary;
@class NSDictionary, ConnectionController, PreferencesController;
@class TopicInspectorController, ServerListController;
@class BundleConfigureController, NSMenu;

@protocol GNUstepOutputBundlePreferences
- (void)shouldDisplay;
- (void)shouldHide;
@end

@interface GNUstepOutput : NSObject 
	{
		NSMutableDictionary *pendingIdentToConnectionController;
		NSMapTable *connectionToConnectionController;
		NSMutableArray *connectionControllers;
		NSMutableArray *serverLists;		
		TopicInspectorController *topic;
		BundleConfigureController *bundle;
		BOOL terminating;
		NSMenu *menu;
	}

- (id)connectionToConnectionController: (id)aObject;

- waitingForConnection: (NSString *)aIdent onConnectionController: (id)controller;

- addConnectionController: (ConnectionController *)aCont;
- removeConnectionController: (ConnectionController *)aCont;
- (NSArray *)connectionControllers;

- (NSArray *)unconnectedConnectionControllers;

- addServerList: (ServerListController *)aServer;
- removeServerList: (ServerListController *)aServer;

- (TopicInspectorController *)topicInspectorController;
- (void)run;
@end

#endif
