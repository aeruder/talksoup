/***************************************************************************
                                Dummy.m
                          -------------------
    begin                : Sat Apr  5 22:03:18 CST 2003
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

#include "Dummy.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSArray.h>

@implementation TalkSoupDummyProtocolClass
- pluginActivated
	{ return nil; }

- pluginDeactivated
	{ return nil; }

- controlObject: (id)aObject onConnection: aConnection sender: aPlugin
	{ return nil; }
	
- changeNick: (NSAttributedString *)aNick onConnection: aConnection 
   sender: aPlugin 
   { return nil; }

- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection 
   sender: aPlugin { return nil; }

- partChannel: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection sender: aPlugin { return nil; }

- joinChannel: (NSAttributedString *)channel 
   withPassword: (NSAttributedString *)aPassword 
   onConnection: aConnection sender: aPlugin { return nil; }

- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection sender: aPlugin 
   { return nil; }

- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection sender: aPlugin 
   { return nil; }

- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin { return nil; }

- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin { return nil; }

- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin { return nil; }

- becomeOperatorWithName: (NSAttributedString *)aName 
   withPassword: (NSAttributedString *)pass 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestNamesOnChannel: (NSAttributedString *)aChannel 
   fromServer: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestMOTDOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestSizeInformationFromServer: (NSAttributedString *)aServer
   andForwardTo: (NSAttributedString *)anotherServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestVersionOfServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestServerStats: (NSAttributedString *)aServer 
   for: (NSAttributedString *)query 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestServerLink: (NSAttributedString *)aLink 
   from: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestTimeOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestServerToConnect: (NSAttributedString *)aServer 
   to: (NSAttributedString *)connectServer
   onPort: (NSAttributedString *)aPort onConnection: aConnection 
   sender: aPlugin 
   { return nil; }

- requestTraceOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestAdministratorOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   sender: aPlugin { return nil; }

- requestInfoOnServer: (NSAttributedString *)aServer onConnection: aConnection
   sender: aPlugin { return nil; }

- requestServiceListWithMask: (NSAttributedString *)aMask 
   ofType: (NSAttributedString *)type 
   onConnection: aConnection sender: aPlugin { return nil; }

- requestServerRehashOnConnection: aConnection sender: aPlugin { return nil; }

- requestServerShutdownOnConnection: aConnection sender: aPlugin { return nil; }

- requestServerRestartOnConnection: aConnection sender: aPlugin { return nil; }

- requestUserInfoOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   sender: aPlugin { return nil; }

- areUsersOn: (NSAttributedString *)userList 
   onConnection: aConnection sender: aPlugin 
   { return nil; }

- sendWallops: (NSAttributedString *)message 
   onConnection: aConnection sender: aPlugin 
   { return nil; }

- queryService: (NSAttributedString *)aService 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection sender: aPlugin { return nil; }

- listWho: (NSAttributedString *)aMask onlyOperators: (BOOL)operators 
   onConnection: aConnection sender: aPlugin { return nil; }

- whois: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- whowas: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer
   withNumberEntries: (NSAttributedString *)aNumber onConnection: aConnection 
   sender: aPlugin { return nil; }

- kill: (NSAttributedString *)aPerson 
   withComment: (NSAttributedString *)aComment 
   onConnection: aConnection sender: aPlugin { return nil; }

- setTopicForChannel: (NSAttributedString *)aChannel 
   to: (NSAttributedString *)aTopic 
   onConnection: aConnection sender: aPlugin { return nil; }

- setMode: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)list onConnection: aConnection sender: aPlugin 
   { return nil; }
					 
- listChannel: (NSAttributedString *)aChannel 
   onServer: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin { return nil; }

- invite: (NSAttributedString *)aPerson to: (NSAttributedString *)aChannel 
   onConnection: aConnection sender: aPlugin { return nil; }

- kick: (NSAttributedString *)aPerson offOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason 
   onConnection: aConnection sender: aPlugin { return nil; }

- setAwayWithMessage: (NSAttributedString *)message onConnection: aConnection 
   sender: aPlugin { return nil; }

- sendPingWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   sender: aPlugin { return nil; }

- sendPongWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   sender: aPlugin { return nil; }

- writeRawString: (NSAttributedString *)aString onConnection: aConnection
   sender: aPlugin { return nil; }

- (NSString *)identification { return nil; }

- newConnection: (id)connection sender: aPlugin { return nil; }

- lostConnection: (id)connection sender: aPlugin { return nil; }

- registeredWithServerOnConnection: (id)connection sender: aPlugin 
   { return nil; }

- couldNotRegister: (NSAttributedString *)reason onConnection: (id)connection 
   sender: aPlugin { return nil; }

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin { return nil; }

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin { return nil; }

- errorReceived: (NSAttributedString *)anError onConnection: (id)connection 
   sender: aPlugin { return nil; }

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin { return nil; }

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection sender: aPlugin { return nil; }
		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection sender: aPlugin { return nil; }

- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin { return nil; }
   
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection sender: aPlugin { return nil; }

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection sender: aPlugin { return nil; }

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection sender: aPlugin { return nil; }

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   sender: aPlugin { return nil; }

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   sender: aPlugin { return nil; }

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   sender: aPlugin { return nil; }

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   sender: aPlugin { return nil; }

- newNickNeededWhileRegisteringOnConnection: (id)connection sender: aPlugin 
   { return nil; }

@end
