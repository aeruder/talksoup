/***************************************************************************
                                main.m
                          -------------------
    begin                : Fri Feb 21 00:51:41 CST 2003
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

#include "main.h"

#include <Foundation/NSInvocation.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSString.h>
#include "Functions.h"

#ifdef S2AS
	#undef S2AS
#endif

#define S2AS(_x) NetClasses_AttributedStringFromString((_x))

#ifdef AS2S
	#undef AS2S
#endif

#define AS2S(_x) NetClasses_StringFromAttributedString((_x))

@interface NetclassesInput (PrivateNetclassesInput)
- removeConnection: aConnection;
@end

@implementation NetclassesInput (PrivateNetclassesInput)
- removeConnection: aConnection
{
	[connections removeObject: aConnection];
	
	return self;
}
@end

@implementation NetclassesInput
- init
{
	if (!(self = [super init])) return nil;

	connections = [[NSMutableArray alloc] init];

	return self;
}
- (void)dealloc
{
	RELEASE(connections);
	[super dealloc];
}
- initiateConnectionToHost: (NSHost *)aHost onPort: (int)aPort
   withTimeout: (int)seconds withNickname: (NSString *)nickname 
   withUserName: (NSString *)user withRealName: (NSString *)realName 
   withPassword: (NSString *)password withIdentification: (NSString *)ident
{
	id connection = [[NetclassesConnection alloc] initWithNickname:
	  nickname withUserName: user withRealName: realName
	  withPassword: password withIdentification: ident onPort: aPort
	  withControl: self];
	
	[[TCPSystem sharedInstance] connectNetObjectInBackground: connection
	  toHost: aHost onPort: aPort withTimeout: seconds];
	
	[connections addObject: connection];

	return self;
}
- (void)closeConnection: (id)connection
{
	if ([connections containsObject: connection])
	{
		[[NetApplication sharedInstance] disconnectObject: connection];
	}
}	
- (NSArray *)connections
{
	return [NSArray arrayWithArray: connections];
}
@end
		 
@implementation NetclassesConnection
- initWithNickname: (NSString *)aNick withUserName: (NSString *)user
   withRealName: (NSString *)real withPassword: (NSString *)aPass
   withIdentification: (NSString *)ident onPort: (int)aPort
   withControl: plugin;
{
	if (!(self = [super initWithNickname: aNick withUserName: user
	  withRealName: real withPassword: aPass])) return nil;

	identification = RETAIN(ident);

	port = aPort;

	control = plugin; // Avoiding circular reference
	
	return self;
}
- (void)dealloc
{
	RELEASE(identification);
	RELEASE(errorMessage);

	[super dealloc];
}
- connectingFailed: (NSString *)error
{
	[control removeConnection: self];
	errorMessage = RETAIN(error);
	[_TS_ lostConnection: self
	 withNickname: S2AS(nick)
	 sender: control];
	return self;
}
- connectingStarted: (TCPConnecting *)aConnection
{
	return self;
}	
- (NSString *)identification
{
	return identification;
}
- (NSString *)errorMessage
{
	return errorMessage;
}
- (int)port
{
	return port;
}
- (NSHost *)host
{
	return [transport address];
}
- (void)connectionLost
{
	[control removeConnection: self];
	[_TS_ lostConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	[super connectionLost];
}
- connectionEstablished: (id)aTransport
{
	id x = [super connectionEstablished: aTransport];
	[_TS_ newConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return x;
}
- registeredWithServer
{
	[_TS_ registeredWithServerOnConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- couldNotRegister: (NSString *)reason
{
	[_TS_ couldNotRegister: S2AS(reason) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- CTCPRequestReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson;
{
	[_TS_ CTCPRequestReceived: S2AS(aCTCP) withArgument: S2AS(argument)
	  from: S2AS(aPerson) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- CTCPReplyReceived: (NSString *)aCTCP
   withArgument: (NSString *)argument from: (NSString *)aPerson
{
	[_TS_ CTCPReplyReceived: S2AS(aCTCP) withArgument: S2AS(argument)
	  from: S2AS(aPerson) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- errorReceived: (NSString *)anError
{
	[_TS_ errorReceived: S2AS(anError) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- wallopsReceived: (NSString *)message from: (NSString *)sender
{
	[_TS_ wallopsReceived: S2AS(message) from: S2AS(sender) onConnection: self
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- userKicked: (NSString *)aPerson outOf: (NSString *)aChannel
         for: (NSString *)reason from: (NSString *)kicker
{
	[_TS_ userKicked: S2AS(aPerson) outOf: S2AS(aChannel) for: S2AS(reason)
	  from: S2AS(kicker) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- invitedTo: (NSString *)aChannel from: (NSString *)inviter
{
	[_TS_ invitedTo: S2AS(aChannel) from: S2AS(inviter) onConnection: self
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- modeChanged: (NSString *)mode on: (NSString *)anObject
   withParams: (NSArray *)paramList from: (NSString *)aPerson
{
	NSMutableArray *y;
	NSEnumerator *iter;
	id object;
	
	y = AUTORELEASE([[NSMutableArray alloc] init]);
	
	iter = [paramList objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[y addObject: S2AS(object)];
	}

	[_TS_ modeChanged: S2AS(mode) on: S2AS(anObject) withParams: 
	  [NSArray arrayWithArray: y] from: S2AS(aPerson) onConnection: self
	  withNickname: S2AS(nick)
	  sender: control];
	return self;
}
- numericCommandReceived: (NSString *)command withParams: (NSArray *)paramList
                      from: (NSString *)sender
{
	NSMutableArray *y;
	NSEnumerator *iter;
	id object;
	
	y = AUTORELEASE([[NSMutableArray alloc] init]);
	
	iter = [paramList objectEnumerator];

	while ((object = [iter nextObject]))
	{
		[y addObject: S2AS(object)];
	}

	[_TS_ numericCommandReceived: S2AS(command) withParams:
	  [NSArray arrayWithArray: y] from: S2AS(sender) onConnection: self
	  withNickname: S2AS(nick)
	  sender: control];

	return self;
}
- nickChangedTo: (NSString *)newName from: (NSString *)aPerson
{	
	[_TS_ nickChangedTo: S2AS(newName) from: S2AS(aPerson) onConnection: self
	  withNickname: S2AS(nick)
	  sender: control];

	return self;
}
- channelJoined: (NSString *)channel from: (NSString *)joiner
{
	[_TS_ channelJoined: S2AS(channel) from: S2AS(joiner) onConnection: self
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- channelParted: (NSString *)channel withMessage: (NSString *)aMessage
             from: (NSString *)parter
{
	[_TS_ channelParted: S2AS(channel) withMessage: S2AS(aMessage)
	  from: S2AS(parter) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];

	return self;
}
- quitIRCWithMessage: (NSString *)aMessage from: (NSString *)quitter
{
	[_TS_ quitIRCWithMessage: S2AS(aMessage) from: S2AS(quitter) 
	  onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- topicChangedTo: (NSString *)aTopic in: (NSString *)channel
              from: (NSString *)aPerson
{
	[_TS_ topicChangedTo: S2AS(aTopic) in: S2AS(channel)
	  from: S2AS(aPerson) onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];

	return self;
}
- messageReceived: (NSString *)aMessage to: (NSString *)to
               from: (NSString *)sender
{
	[_TS_ messageReceived: S2AS(aMessage) to: S2AS(to) from: S2AS(sender)
	  onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- noticeReceived: (NSString *)aMessage to: (NSString *)to
              from: (NSString *)sender
{
	[_TS_ noticeReceived: S2AS(aMessage) to: S2AS(to) from: S2AS(sender)
	  onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- actionReceived: (NSString *)anAction to: (NSString *)to
              from: (NSString *)sender
{
	[_TS_ actionReceived: S2AS(anAction) to: S2AS(to) from: S2AS(sender)
	  onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- pingReceivedWithArgument: (NSString *)arg from: (NSString *)sender
{
	[_TS_ pingReceivedWithArgument: S2AS(arg) from: S2AS(sender) 
	  onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- pongReceivedWithArgument: (NSString *)arg from: (NSString *)sender
{
	[_TS_ pongReceivedWithArgument: S2AS(arg) from: S2AS(sender)
	  onConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- newNickNeededWhileRegistering
{
	[_TS_ newNickNeededWhileRegisteringOnConnection: self 
	  withNickname: S2AS(nick)
	  sender: control];
	
	return self;
}
- changeNick: (NSAttributedString *)newNick onConnection: aConnection 
   withNickname: (NSAttributedString *)theNick sender: aPlugin
{
	[_TS_ changeNick: newNick onConnection: self 
	  withNickname: theNick
	  sender: control];
	[super changeNick: AS2S(newNick)];
	return self;
}	
- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ quitWithMessage: aMessage onConnection: self
	  withNickname: aNick
	  sender: control];
	[super quitWithMessage: AS2S(aMessage)];
	return self;
}
- partChannel: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ partChannel: channel withMessage: aMessage
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super partChannel: AS2S(channel) withMessage: AS2S(aMessage)];
	return self;
}
- joinChannel: (NSAttributedString *)channel 
   withPassword: (NSAttributedString *)aPassword 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ joinChannel: channel withPassword: aPassword onConnection: self
	  withNickname: aNick
	  sender: control];
	[super joinChannel: AS2S(channel) withPassword: AS2S(aPassword)];
	return self;
}
- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendCTCPReply: aCTCP withArgument: args to: aPerson
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super sendCTCPReply: AS2S(aCTCP) withArgument: AS2S(args)
	  to: AS2S(aPerson)];
	return self;
}
- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendCTCPRequest: aCTCP withArgument: args
	  to: aPerson onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super sendCTCPRequest: AS2S(aCTCP) withArgument: AS2S(args)
	  to: AS2S(aPerson)];
	return self;
} 
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendMessage: message to: receiver onConnection: self
	  withNickname: aNick
	  sender: control];
	[super sendMessage: AS2S(message) to: AS2S(receiver)];
	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendNotice: message to: receiver onConnection: self
	  withNickname: aNick
	  sender: control];
	[super sendNotice: AS2S(message) to: AS2S(receiver)];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendAction: anAction to: receiver
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super sendAction: AS2S(anAction) to: AS2S(receiver)];
	return self;
}
- becomeOperatorWithName: (NSAttributedString *)aName 
   withPassword: (NSAttributedString *)pass 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ becomeOperatorWithName: aName withPassword: pass
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super becomeOperatorWithName: AS2S(aName) withPassword: AS2S(pass)];
	return self;
}
- requestNamesOnChannel: (NSAttributedString *)aChannel 
   fromServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestNamesOnChannel: aChannel
	  fromServer: aServer onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestNamesOnChannel: AS2S(aChannel)
	  fromServer: AS2S(aServer)];
	return self;
}
- requestMOTDOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestMOTDOnServer: aServer onConnection: self
	  withNickname: aNick
	  sender: control];
	[super requestMOTDOnServer: AS2S(aServer)];
	return self;
}
- requestSizeInformationFromServer: (NSAttributedString *)aServer
   andForwardTo: (NSAttributedString *)anotherServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestSizeInformationFromServer: aServer
	  andForwardTo: anotherServer onConnection: self
	  withNickname: aNick
	  sender: control];
	[super requestSizeInformationFromServer: AS2S(aServer)
	  andForwardTo: AS2S(anotherServer)];
	return self;
}
- requestVersionOfServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestVersionOfServer: aServer
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestVersionOfServer: AS2S(aServer)];
	return self;
}
- requestServerStats: (NSAttributedString *)aServer 
   for: (NSAttributedString *)query 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServerStats: aServer for: query
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestServerStats: AS2S(aServer) for: AS2S(query)];
	return self;
}
- requestServerLink: (NSAttributedString *)aLink 
   from: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServerLink: aLink
	 from: aServer onConnection: self 
	  withNickname: aNick
	 sender: control];
	[super requestServerLink: AS2S(aLink) from: AS2S(aServer)];
	return self;
}
- requestTimeOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestTimeOnServer: aServer onConnection: self 
	  withNickname: aNick
	 sender: control];
	[super requestTimeOnServer: AS2S(aServer)];
	return self;
}
- requestServerToConnect: (NSAttributedString *)aServer 
   to: (NSAttributedString *)connectServer
   onPort: (NSAttributedString *)aPort onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServerToConnect: aServer to: connectServer
	  onPort: aPort onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestServerToConnect: AS2S(aServer) to: AS2S(connectServer)
	  onPort: AS2S(aPort)];	
	return self;
}
- requestTraceOnServer: (NSAttributedString *)aServer onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestTraceOnServer: aServer onConnection: self
	  withNickname: aNick
	  sender: control];
	[super requestTraceOnServer: AS2S(aServer)];
	return self;
}
- requestAdministratorOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestAdministratorOnServer: aServer onConnection: self
	  withNickname: aNick
	  sender: control];
	[super requestAdministratorOnServer: AS2S(aServer)];
	return self;
}
- requestInfoOnServer: (NSAttributedString *)aServer onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestInfoOnServer: aServer onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestInfoOnServer: AS2S(aServer)];
	return self;
}
- requestServiceListWithMask: (NSAttributedString *)aMask 
   ofType: (NSAttributedString *)type 
   onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServiceListWithMask: aMask ofType: type
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestServiceListWithMask: AS2S(aMask)
	  ofType: AS2S(type)];
	return self;
}
- requestServerRehashOnConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServerRehashOnConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestServerRehash];
	return self;
}
- requestServerShutdownOnConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServerShutdownOnConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestServerShutdown];
	return self;
}
- requestServerRestartOnConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestServerRestartOnConnection: self 
	  withNickname: aNick
	  sender: control];
	[super requestServerRestart];
	return self;
}
- requestUserInfoOnServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ requestUserInfoOnServer: aServer onConnection: self
	  withNickname: aNick
	  sender: control];
	[super requestUserInfoOnServer: AS2S(aServer)];
	return self;
}
- areUsersOn: (NSAttributedString *)userList onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ areUsersOn: userList onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super areUsersOn: AS2S(userList)];
	return self;
}
- sendWallops: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendWallops: message onConnection: self
	  withNickname: aNick
	  sender: control];
	[super sendWallops: AS2S(message)];
	return self;
}
- queryService: (NSAttributedString *)aService 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ queryService: aService withMessage: aMessage
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super queryService: AS2S(aService)
	  withMessage: AS2S(aMessage)];
	return self;
}
- listWho: (NSAttributedString *)aMask onlyOperators: (BOOL)operators 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ listWho: aMask onlyOperators: operators onConnection: self
	  withNickname: aNick
	  sender: control];
	[super listWho: AS2S(aMask) onlyOperators: operators];
	return self;
}
- whois: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ whois: aPerson onServer: aServer onConnection: self
	  withNickname: aNick
	  sender: control];
	[super whois: AS2S(aPerson) onServer: AS2S(aServer)];
	return self;
}
- whowas: (NSAttributedString *)aPerson onServer: (NSAttributedString *)aServer
   withNumberEntries: (NSAttributedString *)aNumber onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ whowas: aPerson onServer: aServer withNumberEntries: aNumber
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super whowas: AS2S(aPerson) onServer: AS2S(aServer)
	  withNumberEntries: AS2S(aNumber)];
	return self;
}
- kill: (NSAttributedString *)aPerson 
   withComment: (NSAttributedString *)aComment 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ kill: aPerson withComment: aComment onConnection: self
	  withNickname: aNick
	  sender: control];
	[super kill: AS2S(aPerson) withComment: AS2S(aComment)];
	return self;
}
- setTopicForChannel: (NSAttributedString *)aChannel 
   to: (NSAttributedString *)aTopic 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ setTopicForChannel: aChannel
	  to: aTopic onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super setTopicForChannel: AS2S(aChannel) to: AS2S(aTopic)];
	return self;
}
- setMode: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)list onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	NSMutableArray *a;
	NSEnumerator *iter;
	id object;
	
	[_TS_ setMode: aMode on: anObject withParams: list
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	a = AUTORELEASE([NSMutableArray new]);
	iter = [list objectEnumerator];
	while ((object = [iter nextObject]))
	{
		[a addObject: AS2S(object)];
	}
	
	[super setMode: AS2S(aMode) on: AS2S(anObject) withParams:
	 a];
	
	return self;
}					 
- listChannel: (NSAttributedString *)aChannel 
   onServer: (NSAttributedString *)aServer 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ listChannel: aChannel onServer: aServer
	  onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super listChannel: AS2S(aChannel) onServer: AS2S(aServer)];
	return self;
}
- invite: (NSAttributedString *)aPerson to: (NSAttributedString *)aChannel 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ invite: aPerson to: aChannel onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super invite: AS2S(aPerson) to: AS2S(aChannel)];
	return self;
}
- kick: (NSAttributedString *)aPerson offOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ kick: aPerson offOf: aChannel for: reason onConnection: self
	  withNickname: aNick
	  sender: control];
	[super kick: AS2S(aPerson) offOf: AS2S(aChannel) for: AS2S(reason)];
	return self;
}
- setAwayWithMessage: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ setAwayWithMessage: message onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super setAwayWithMessage: AS2S(message)];
	return self;
}
- sendPingWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendPingWithArgument: aString onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super sendPingWithArgument: AS2S(aString)];
	return self;
}
- sendPongWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendPongWithArgument: aString onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super sendPongWithArgument: AS2S(aString)];
	return self;
}
- writeRawString: (NSAttributedString *)aString onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ writeRawString: aString onConnection: self 
	  withNickname: aNick
	  sender: control];
	[super writeString: @"%@", AS2S(aString)];
	return self;
}
@end
