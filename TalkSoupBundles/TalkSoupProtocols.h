/***************************************************************************
                                TalkSoupProtocols.h
                          -------------------
    begin                : Mon Apr  7 20:46:46 CDT 2003
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

#ifndef TALKSOUP_PROTOCOLS_H
#define TALKSOUP_PROTOCOLS_H

@class NSInvocation, NSMutableArray, NSString, NSAttributedString;
@class NSHost, NSMutableDictionary;

@protocol TalkSoupInputPluginProtocol 
- initiateConnectionToHost: (NSHost *)aHost onPort: (int)aPort
   withTimeout: (int)seconds withNickname: (NSString *)nickname 
   withUserName: (NSString *)user withRealName: (NSString *)realName 
   withPassword: (NSString *)password withIdentification: (NSString *)ident;

- (void)closeConnection: (id)connection;

- (NSArray *)connections;
@end

@protocol TalkSoupOutFilterProtocol
- changeNick: (NSAttributedString *)aNick onConnection: aConnection 
   sender: aPlugin; 

- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection 
   sender: aPlugin;

- partChannel: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection sender: aPlugin;

- joinChannel: (NSAttributedString *)channel 
   withPassword: (NSAttributedString *)aPassword 
   onConnection: aConnection sender: aPlugin;

- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection sender: aPlugin; 

- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection sender: aPlugin; 
  
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin;

- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin;

- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection sender: aPlugin;

- becomeOperatorWithName: (NSAttributedString *)aName 
   withPassword: (NSAttributedString *)pass 
   onConnection: aConnection sender: aPlugin;

- requestNamesOnChannel: (NSAttributedString *)aChannel 
   fromServer: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin;

- requestMOTDOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestSizeInformationFromServer: (NSAttributedString *)aServer
   andForwardTo: (NSAttributedString *)anotherServer onConnection: aConnection 
   sender: aPlugin;

- requestVersionOfServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   sender: aPlugin;

- requestServerStats: (NSAttributedString *)aServer 
   for: (NSAttributedString *)query 
   onConnection: aConnection sender: aPlugin;

- requestServerLink: (NSAttributedString *)aLink 
   from: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin;

- requestTimeOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestServerToConnect: (NSAttributedString *)aServer 
   to: (NSAttributedString *)connectServer
   onPort: (NSAttributedString *)aPort onConnection: aConnection 
   sender: aPlugin;

- requestTraceOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   sender: aPlugin;

- requestAdministratorOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   sender: aPlugin;

- requestInfoOnServer: (NSAttributedString *)aServer onConnection: aConnection
   sender: aPlugin;

- requestServiceListWithMask: (NSAttributedString *)aMask 
   ofType: (NSAttributedString *)type 
   onConnection: aConnection sender: aPlugin;

- requestServerRehashOnConnection: aConnection sender: aPlugin;

- requestServerShutdownOnConnection: aConnection sender: aPlugin;

- requestServerRestartOnConnection: aConnection sender: aPlugin;

- requestUserInfoOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   sender: aPlugin;

- areUsersOn: (NSAttributedString *)userList onConnection: aConnection 
   sender: aPlugin;

- sendWallops: (NSAttributedString *)message onConnection: aConnection 
   sender: aPlugin;

- queryService: (NSAttributedString *)aService 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection sender: aPlugin;

- listWho: (NSAttributedString *)aMask onlyOperators: (BOOL)operators 
   onConnection: aConnection sender: aPlugin;

- whois: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin;

- whowas: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer
   withNumberEntries: (NSAttributedString *)aNumber onConnection: aConnection 
   sender: aPlugin;

- kill: (NSAttributedString *)aPerson 
   withComment: (NSAttributedString *)aComment 
   onConnection: aConnection sender: aPlugin;

- setTopicForChannel: (NSAttributedString *)aChannel 
   to: (NSAttributedString *)aTopic 
   onConnection: aConnection sender: aPlugin;

- setMode: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)list onConnection: aConnection sender: aPlugin;
					 
- listChannel: (NSAttributedString *)aChannel 
   onServer: (NSAttributedString *)aServer 
   onConnection: aConnection sender: aPlugin;

- invite: (NSAttributedString *)aPerson to: (NSAttributedString *)aChannel 
   onConnection: aConnection sender: aPlugin;

- kick: (NSAttributedString *)aPerson offOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason 
   onConnection: aConnection sender: aPlugin;

- setAwayWithMessage: (NSAttributedString *)message onConnection: aConnection 
   sender: aPlugin;

- sendPingWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   sender: aPlugin;

- sendPongWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   sender: aPlugin;

- writeRawString: (NSAttributedString *)aString onConnection: aConnection
   sender: aPlugin;
@end

@protocol TalkSoupConnectionProtocol < TalkSoupOutFilterProtocol >
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

- consoleMessage: (NSAttributedString *)arg onConnection: (id)aConnection;

- systemMessage: (NSAttributedString *)arg onConnection: (id)aConnection;

- showMessage: (NSAttributedString *)arg onConnection: (id)aConnection;
@end

#endif
