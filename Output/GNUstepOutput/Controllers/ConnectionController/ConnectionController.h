/***************************************************************************
                                ConnectionController.h
                          -------------------
    begin                : Sun Mar 30 21:53:38 CST 2003
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

@class ConnectionController;

#ifndef CONNECTION_CONTROLLER_H
#define CONNECTION_CONTROLLER_H

@class NSString, KeyTextView, ContentController, NSArray;
@class NSColor, Channel, NSMutableDictionary, GNUstepOutput, NSFont;
@class NSDictionary, InputController;

#import "Controllers/ContentControllers/ContentController.h"
#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>

@interface ConnectionController : NSObject
	{
		NSString *typedHost;
		int typedPort;
		
		NSString *preNick;
		NSString *userName;
		NSString *password;
		NSString *realName;
		NSString *server;
		
		NSString * (*lowercase)(NSString *);
		id connection;
		id <ContentController> content;
		NSArray *tabCompletion;
		int tabCompletionIndex;
		
		NSMutableDictionary *nameToChannelData;
		NSMapTable *inputToName;
		
		BOOL registered;
	}
- initWithIRCInfoDictionary: (NSDictionary *)aDict;

- initWithIRCInfoDictionary: (NSDictionary *)aDict 
   withContentController: (id <ContentController>)aContent;

- connectToServer: (NSString *)aName onPort: (int)aPort;

- (Channel *)dataForChannelWithName: (NSString *)aName;
- (NSString *)nameForInputController: (InputController *)aInputController;

- setNick: (NSString *)aString;
- (NSString *)nick;

- setRealName: (NSString *)aString;
- (NSString *)realName;

- setUserName: (NSString *)aString;
- (NSString *)userName;

- setPassword: (NSString *)aString;
- (NSString *)password;

- (NSString *)serverString;

- (NSString * (*)(NSString *))lowercasingFunction;
- (void)setLowercasingFunction: (NSString * (*)(NSString *))aFunction;

- (id)connection;

- (id <ContentController>)contentController;
- (void)setContentController: (id <ContentController>)aController;

- (NSArray *)channelsWithUser: (NSString *)user;

- leaveChannel: (NSString *)channel;
@end

/* 
	object:         The view controller
	
	userinfo:
	@"Channel"      Channel data
	@"Content":     The content controller
*/
extern NSString *ConnectionControllerUpdatedTopicNotification;

#endif
