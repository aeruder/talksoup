/***************************************************************************
                                ConnectionController.h
                          -------------------
    begin                : Sun Mar 30 21:53:38 CST 2003
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

@class ConnectionController;

#ifndef CONNECTION_CONTROLLER_H
#define CONNECTION_CONTROLLER_H

@class NSString, NSAttributedString, NSDictionary, InputController, ContentController;
@class NSColor, NSMutableDictionary, KeyTextView, Channel;

#include <Foundation/NSObject.h>

@interface ConnectionController : NSObject
	{
		NSString *typedHost;
		int typedPort;
		
		NSString *preNick;
		NSString *userName;
		NSString *password;
		NSString *realName;
		
		KeyTextView *fieldEditor;
		InputController *inputController;
		id connection;
		ContentController *content;
		NSArray *tabCompletion;
		int tabCompletionIndex;
		
		NSColor *personalColor;
		NSColor *otherColor;
		
		NSMutableDictionary *nameToChannelData;
		
		BOOL registered;
	}
- initWithIRCInfoDictionary: (NSDictionary *)aDict;

- connectToServer: (NSString *)aName onPort: (int)aPort;

- updateTopicInspector;

- (Channel *)dataForChannelWithName: (NSString *)aName;

- setNick: (NSString *)aString;
- (NSString *)nick;

- setRealName: (NSString *)aString;
- (NSString *)realName;

- setUserName: (NSString *)aString;
- (NSString *)userName;

- setPassword: (NSString *)aString;
- (NSString *)password;

- (InputController *)inputController;

- (id)connection;

- (ContentController *)contentController;

- (NSArray *)channelsWithUser: (NSString *)user;

- (NSColor *)otherColor;
- setOtherColor: (NSColor *)aColor;
- (NSColor *)personalColor;
- setPersonalColor: (NSColor *)aColor;

- newConnection: (id)connection sender: aPlugin;

- registeredWithServerOnConnection: (id)connection sender: aPlugin;

- couldNotRegister: (NSAttributedString *)reason onConnection: (id)connection 
   sender: aPlugin;

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin;

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin;

- errorReceived: (NSAttributedString *)anError onConnection: (id)connection 
   sender: aPlugin;

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin;

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection sender: aPlugin;
		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection sender: aPlugin;

- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin;
   
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin;

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin;

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection sender: aPlugin;

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   sender: aPlugin;

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   sender: aPlugin;

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin;

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- pingReceivedWithArgument: (NSAttributedString *)arg  
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin;

- newNickNeededWhileRegisteringOnConnection: (id)connection sender: aPlugin;

- consoleMessage: (NSAttributedString *)arg onConnection: (id)connection;

- systemMessage: (NSAttributedString *)arg onConnection: (id)connection;

- showMessage: (NSAttributedString *)arg onConnection: (id)connection;
@end

#endif
