/***************************************************************************
                                Emoticon.h
                          -------------------
    begin                : Mon Jan 12 21:08:33 CST 2004
    copyright            : original(GNUMail)-Ludovic Marcotte Copyright 2003
                           TalkSoup adaptation-Andrew Ruder Copyright 2003
    email                : Andrew Ruder: aeruder@ksu.edu
                           Ludovic Marcotte: ludovic@Sophos.ca
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/

@class Emoticon;

#ifndef EMOTICON_H
#define EMOTICON_H

#import <Foundation/NSObject.h>

@class NSBundle, NSAttributedString;

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [Emoticon class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

@interface Emoticon : NSObject
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
   sender: aPlugin;

- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- messageReceived: (NSAttributedString *)aMessage to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;

- actionReceived: (NSAttributedString *)anAction to: (NSAttributedString *)to
   from: (NSAttributedString *)sender onConnection: (id)connection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin;
@end

#endif 
