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

@protocol TalkSoupPluginProtocol
- pluginActivated;

- pluginDeactivated;

- controlObject: (id)aObject onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick
   sender: aPlugin;

- (NSAttributedString *)pluginDescription;
@end

@protocol TalkSoupInputPluginProtocol < TalkSoupPluginProtocol > 
- initiateConnectionToHost: (NSHost *)aHost onPort: (int)aPort
   withTimeout: (int)seconds withNickname: (NSString *)nickname 
   withUserName: (NSString *)user withRealName: (NSString *)realName 
   withPassword: (NSString *)password withIdentification: (NSString *)ident;

- (void)closeConnection: (id)connection;

- (NSArray *)connections;
@end

@protocol TalkSoupOutFilterProtocol < TalkSoupPluginProtocol >
- changeNick: (NSAttributedString *)aNick onConnection: aConnection 
   withNickname: (NSAttributedString *)nick sender: aPlugin; 

- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- partChannel: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- joinChannel: (NSAttributedString *)channel 
   withPassword: (NSAttributedString *)aPassword 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin; 

- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin; 
  
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
	sender: aPlugin;

- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- becomeOperatorWithName: (NSAttributedString *)aName 
   withPassword: (NSAttributedString *)pass 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestNamesOnChannel: (NSAttributedString *)aChannel 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestMOTDOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
   sender: aPlugin;

- requestSizeInformationFromServer: (NSAttributedString *)aServer
   andForwardTo: (NSAttributedString *)anotherServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestVersionOfServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestServerStats: (NSAttributedString *)aServer 
   for: (NSAttributedString *)query 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestServerLink: (NSAttributedString *)aLink 
   from: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestTimeOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestServerToConnect: (NSAttributedString *)aServer 
   to: (NSAttributedString *)connectServer
   onPort: (NSAttributedString *)aPort onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestTraceOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestAdministratorOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestInfoOnServer: (NSAttributedString *)aServer onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestServerRehashOnConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestServerShutdownOnConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestServerRestartOnConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- requestUserInfoOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- areUsersOn: (NSAttributedString *)userList onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- sendWallops: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- listWho: (NSAttributedString *)aMask onlyOperators: (BOOL)operators 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- whois: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- whowas: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer
   withNumberEntries: (NSAttributedString *)aNumber onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- kill: (NSAttributedString *)aPerson 
   withComment: (NSAttributedString *)aComment 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- setTopicForChannel: (NSAttributedString *)aChannel 
   to: (NSAttributedString *)aTopic 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- setMode: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)list onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
					 
- listChannel: (NSAttributedString *)aChannel 
   onServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- invite: (NSAttributedString *)aPerson to: (NSAttributedString *)aChannel 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- kick: (NSAttributedString *)aPerson offOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- setAwayWithMessage: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- sendPingWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- sendPongWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- writeRawString: (NSAttributedString *)aString onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
@end

@protocol TalkSoupConnectionProtocol < TalkSoupOutFilterProtocol >
- (NSString *)identification;

- (NSString *)errorMessage;

- (BOOL)connected;

- (NSString *)nick;

- (int)port;

- (NSHost *)remoteHost;

- (NSHost *)localHost;

- setEncoding: (NSStringEncoding)encoding;

- (NSStringEncoding)encoding;
@end

@protocol TalkSoupInFilterProtocol < TalkSoupPluginProtocol >
- newConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- lostConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- registeredWithServerOnConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- couldNotRegister: (NSAttributedString *)reason onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- errorReceived: (NSAttributedString *)anError onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
		 
- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- modeChanged: (NSAttributedString *)mode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
   
- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

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

- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- newNickNeededWhileRegisteringOnConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
@end

@protocol TalkSoupOutputPluginProtocol < TalkSoupInFilterProtocol >
- (void)run;

- consoleMessage: (NSAttributedString *)arg onConnection: (id)aConnection;

- systemMessage: (NSAttributedString *)arg onConnection: (id)aConnection;

- showMessage: (NSAttributedString *)arg onConnection: (id)aConnection;
@end

#endif
