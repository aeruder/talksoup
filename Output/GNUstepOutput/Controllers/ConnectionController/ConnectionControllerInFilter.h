/***************************************************************************
                                ConnectionControllerInFilter.h
                          -------------------
    begin                : Tue May 20 18:38:20 CDT 2003
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

#ifndef CONNECTION_CONTROLLER_IN_FILTER_H
#define CONNECTION_CONTROLLER_IN_FILTER_H

#include "Controllers/ConnectionController/ConnectionController.h"

@class NSAttributedString;

@interface ConnectionController (InFilter)
- newConnection: (id)aConnection withNickname: (NSAttributedString *)aNick
   sender: aPlugin;

- lostConnection: (id)aConnection withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- controlObject: (id)aObject onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- registeredWithServerOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- couldNotRegister: (NSAttributedString *)reason onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- CTCPRequestReceived: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- errorReceived: (NSAttributedString *)anError onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- userKicked: (NSAttributedString *)aPerson 
   outOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason from: (NSAttributedString *)kicker 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- invitedTo: (NSAttributedString *)aChannel from: (NSAttributedString *)inviter 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- modeChanged: (NSAttributedString *)aMode on: (NSAttributedString *)anObject 
   withParams: (NSArray *)paramList from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- numericCommandReceived: (NSAttributedString *)command 
   withParams: (NSArray *)paramList from: (NSAttributedString *)sender 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- nickChangedTo: (NSAttributedString *)newName 
   from: (NSAttributedString *)aPerson 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- channelJoined: (NSAttributedString *)channel 
   from: (NSAttributedString *)joiner 
   onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- channelParted: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage
   from: (NSAttributedString *)parter onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- quitIRCWithMessage: (NSAttributedString *)aMessage 
   from: (NSAttributedString *)quitter onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- topicChangedTo: (NSAttributedString *)aTopic in: (NSAttributedString *)channel
   from: (NSAttributedString *)aPerson onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- noticeReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- actionReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- pingReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- pongReceivedWithArgument: (NSAttributedString *)arg 
   from: (NSAttributedString *)sender onConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- newNickNeededWhileRegisteringOnConnection: (id)aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- consoleMessage: (NSAttributedString *)arg onConnection: (id)connection;

- systemMessage: (NSAttributedString *)arg onConnection: (id)connection;

- showMessage: (NSAttributedString *)arg onConnection: (id)connection;
@end

#endif

