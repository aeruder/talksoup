/***************************************************************************
                             Dereverse.h
                          -------------------
    begin                : Sat May 10 18:58:30 CDT 2003
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

@class Dereverse;

#ifndef DEREVERSE_H
#define DEREVERSE_H

#import <Foundation/NSObject.h>

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [Dereverse class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

@class NSAttributedString;

@interface Dereverse : NSObject
- CTCPReplyReceived: (NSAttributedString *)aCTCP
   withArgument: (NSAttributedString *)argument 
   to: (NSAttributedString *)receiver
   from: (NSAttributedString *)aPerson 
   onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- wallopsReceived: (NSAttributedString *)message 
   from: (NSAttributedString *)sender 
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
@end

#endif
