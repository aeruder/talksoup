/***************************************************************************
                                Highlighting.h
                          -------------------
    begin                : Fri May  2 16:48:50 CDT 2003
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

@class Highlighting;

#ifndef HIGHLIGHTING_H
#define HIGHLIGHTING_H

@class NSBundle;

#import <Foundation/NSObject.h>

#ifdef _l
	#undef _l
#endif

#define _l(X) [[NSBundle bundleForClass: [Highlighting class]] \
               localizedStringForKey: (X) value: nil \
               table: @"Localizable"]

@class NSAttributedString;
@class NSString, NSDictionary;

extern NSString *HighlightingShouldDoNick;
extern NSString *HighlightingUserColor;
extern NSString *HighlightingTabReferenceColor;
extern NSString *HighlightingTabAnythingColor;
extern NSString *HighlightingExtraWords;

@interface Highlighting : NSObject
	{
		id controller;
	}

+ (NSDictionary *)defaultSettings;
+ (void)setDefaultsObject: aObject forKey: aKey;
+ (id)defaultsObjectForKey: aKey;
+ (id)defaultDefaultsForKey: aKey;

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

/**
 * This notification is put out everytime something is highlighted.
 * This can be used by other bundles to trap highlighting without having
 * to have their own preferences on extra words and such...
 */
extern NSString *TalkSoupHighlightingNotification;

/* TalkSoupHighlightingNotification = @"TalkSoupHighlightingNotification"
   object: the message (NSAttributedString)
   userinfo:
     @"Message": The message (NSAttributedString)
	 @"Type": The type (@"Action", @"Notice", @"Message") (NSString)
	 @"From": The person who sent it (NSAttributedString)
	 @"FromFull": The person who sent it with full prefix information (NSAttributedString)
	 @"To": Who it was sent to. (NSAttributedString)
	 @"Connection": the connection (id <TalkSoupConnectionProtocol>)
*/

/**
 * This notification is sent out everytime a private message is received
 */
extern NSString *TalkSoupPrivateMessageNotification;
/* TalkSoupPrivateMessageNotification = @"TalkSoupPrivateMessageNotification"
   object: the message (NSAttributedString)
   userinfo:
     @"Message": The message (NSAttributedString)
	 @"Type": The type (@"Action", @"Notice", @"Message") (NSString)
	 @"From": The person who sent it (NSAttributedString)
	 @"FromFull": The person who sent it with full prefix information (NSAttributedString)
	 @"To": Who it was sent to. (NSAttributedString)
	 @"Connection": the connection (id <TalkSoupConnectionProtocol>)
*/
#endif
