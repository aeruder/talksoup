/***************************************************************************
                                TalkSoup.h
                          -------------------
    begin                : Fri Jan 17 11:04:36 CST 2003
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

@class TalkSoup, TalkSoupDummyProtocolClass;

#ifndef TALKSOUP_H
#define TALKSOUP_H

#include <Foundation/NSObject.h>

@class TalkSoup, NSInvocation, NSMutableArray, NSString, NSAttributedString;
@class NSHost, NSMutableDictionary;

extern void BuildPluginList();
extern NSArray *InputPluginList;
extern NSArray *InFilterPluginList;
extern NSArray *OutFilterPluginList;
extern NSArray *OutputPluginList;

// Attributed string stuff

// Key
extern NSString *IRCColor;
// Values
extern NSString *IRCColorWhite;
extern NSString *IRCColorBlack;
extern NSString *IRCColorBlue;
extern NSString *IRCColorGreen;
extern NSString *IRCColorRed;
extern NSString *IRCColorMaroon;
extern NSString *IRCColorMagenta;
extern NSString *IRCColorOrange;
extern NSString *IRCColorYellow;
extern NSString *IRCColorLightGreen;
extern NSString *IRCColorTeal;
extern NSString *IRCColorLightCyan;
extern NSString *IRCColorLightBlue;
extern NSString *IRCColorLightMagenta;
extern NSString *IRCColorGrey;
extern NSString *IRCColorLightGrey;

@protocol TalkSoupInputPluginProtocol 
- initiateConnectionToHost: (NSHost *)aHost onPort: (int)aPort
   withTimeout: (int)seconds withNickname: (NSString *)nickname 
   withUserName: (NSString *)user withRealName: (NSString *)realName 
   withPassword: (NSString *)password withIdentification: (NSString *)ident;

- (void)closeConnection: (id)connection;

- (NSArray *)connections;
@end

@protocol TalkSoupOutFilterProtocol
- changeNick: (NSString *)aNick onConnection: aConnection sender: aPlugin;

- quitWithMessage: (NSString *)aMessage onConnection: aConnection 
   sender: aPlugin;

- partChannel: (NSString *)channel withMessage: (NSString *)aMessage 
   onConnection: aConnection sender: aPlugin;

- joinChannel: (NSString *)channel withPassword: (NSString *)aPassword 
   onConnection: aConnection sender: aPlugin;

- sendCTCPReply: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson onConnection: aConnection sender: aPlugin;

- sendCTCPRequest: (NSString *)aCTCP withArgument: (NSString *)args
   to: (NSString *)aPerson onConnection: aConnection sender: aPlugin;

- sendMessage: (NSString *)message to: (NSString *)receiver 
   onConnection: aConnection sender: aPlugin;

- sendNotice: (NSString *)message to: (NSString *)receiver 
   onConnection: aConnection sender: aPlugin;

- sendAction: (NSString *)anAction to: (NSString *)receiver 
   onConnection: aConnection sender: aPlugin;

- becomeOperatorWithName: (NSString *)aName withPassword: (NSString *)pass 
   onConnection: aConnection sender: aPlugin;

- requestNamesOnChannel: (NSString *)aChannel fromServer: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin;

- requestMOTDOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestSizeInformationFromServer: (NSString *)aServer
   andForwardTo: (NSString *)anotherServer onConnection: aConnection 
   sender: aPlugin;

- requestVersionOfServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestServerStats: (NSString *)aServer for: (NSString *)query 
   onConnection: aConnection sender: aPlugin;

- requestServerLink: (NSString *)aLink from: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin;

- requestTimeOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestServerToConnect: (NSString *)aServer to: (NSString *)connectServer
   onPort: (NSString *)aPort onConnection: aConnection sender: aPlugin;

- requestTraceOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestAdministratorOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestInfoOnServer: (NSString *)aServer onConnection: aConnection
   sender: aPlugin;

- requestServiceListWithMask: (NSString *)aMask ofType: (NSString *)type 
   onConnection: aConnection sender: aPlugin;

- requestServerRehashOnConnection: aConnection sender: aPlugin;

- requestServerShutdownOnConnection: aConnection sender: aPlugin;

- requestServerRestartOnConnection: aConnection sender: aPlugin;

- requestUserInfoOnServer: (NSString *)aServer onConnection: aConnection 
   sender: aPlugin;

- areUsersOn: (NSString *)userList onConnection: aConnection sender: aPlugin;

- sendWallops: (NSString *)message onConnection: aConnection sender: aPlugin;

- queryService: (NSString *)aService withMessage: (NSString *)aMessage 
   onConnection: aConnection sender: aPlugin;

- listWho: (NSString *)aMask onlyOperators: (BOOL)operators 
   onConnection: aConnection sender: aPlugin;

- whois: (NSString *)aPerson onServer: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin;

- whowas: (NSString *)aPerson onServer: (NSString *)aServer
   withNumberEntries: (NSString *)aNumber onConnection: aConnection 
   sender: aPlugin;

- kill: (NSString *)aPerson withComment: (NSString *)aComment 
   onConnection: aConnection sender: aPlugin;

- setTopicForChannel: (NSString *)aChannel to: (NSString *)aTopic 
   onConnection: aConnection sender: aPlugin;

- setMode: (NSString *)aMode on: (NSString *)anObject 
   withParams: (NSArray *)list onConnection: aConnection sender: aPlugin;
					 
- listChannel: (NSString *)aChannel onServer: (NSString *)aServer 
   onConnection: aConnection sender: aPlugin;

- invite: (NSString *)aPerson to: (NSString *)aChannel 
   onConnection: aConnection sender: aPlugin;

- kick: (NSString *)aPerson offOf: (NSString *)aChannel for: (NSString *)reason 
   onConnection: aConnection sender: aPlugin;

- setAwayWithMessage: (NSString *)message onConnection: aConnection 
   sender: aPlugin;

- sendPingWithArgument: (NSString *)aString onConnection: aConnection 
   sender: aPlugin;

- sendPongWithArgument: (NSString *)aString onConnection: aConnection 
   sender: aPlugin;

- writeRawString: (NSString *)aString onConnection: aConnection
   sender: aPlugin;
@end

@protocol TalkSoupConnectionProtocol <TalkSoupOutFilterProtocol>
- (NSString *)identification;

- (BOOL)connected;

- (NSString *)nick;

- (int)port;

- (NSHost *)host;
@end

@protocol TalkSoupInFilterProtocol
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
@end

@protocol TalkSoupOutputPluginProtocol < TalkSoupInFilterProtocol >
- (void)run;

- consoleMessage: (NSAttributedString *)arg;

- systemMessage: (NSAttributedString *)arg;

- showMessage: (NSAttributedString *)arg;
@end

extern id _TS_;
extern id _TSDummy_;

@interface TalkSoup : NSObject
	{
		id input;
		NSMutableArray *outFilters;
		NSMutableArray *inFilters;
		id output;
		NSMutableDictionary *commandList;
	}
+ (TalkSoup *)sharedInstance;

- (NSDictionary *)commandList;
- addCommand: (NSString *)aCommand withInvocation: (NSInvocation *)invoc;
- removeCommand: (NSString *)aCommand;

- (id)input;
- (NSMutableArray *)inFilters;
- (NSMutableArray *)outFilters;
- (id)output;

- setInput: (id)aInput;
- setOutput: (id)aOutput;
@end

@interface TalkSoupDummyProtocolClass : NSObject
@end

#endif
