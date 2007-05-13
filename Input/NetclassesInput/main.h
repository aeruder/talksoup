/***************************************************************************
                                main.h
                          -------------------
    begin                : Fri Feb 21 00:52:16 CST 2003
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

#import <netclasses/IRCObject.h>
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSObject.h>

@interface NetclassesInput : NSObject
	{
		NSMutableArray *connections;
	}

- initiateConnectionToHost: (NSHost *)aHost onPort: (int)aPort
   withTimeout: (int)seconds withNickname: (NSString *)nickname 
   withUserName: (NSString *)user withRealName: (NSString *)realName 
   withPassword: (NSString *)password withIdentification: (NSString *)ident;

- (NSArray *)connections;
@end

@interface NetclassesConnection : IRCObject <TCPConnecting>
	{
		NSString *identification;
		NSString *errorMessage;
		int port;
		id control;
	}
- initWithNickname: (NSString *)aNick withUserName: (NSString *)user
   withRealName: (NSString *)real withPassword: (NSString *)aPass
   withIdentification: (NSString *)ident onPort: (int)aPort
   withControl: plugin;

- connectingFailed: (NSString *)error;

- connectingStarted: (TCPConnecting *)aConnection;

- (NSString *)errorMessage;

- (NSString *)identification;

- (int)port;

- (NSHost *)remoteHost;

- (NSHost *)localHost;
@end

