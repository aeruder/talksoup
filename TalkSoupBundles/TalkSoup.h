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

@class TalkSoup, TalkSoupDummyProtocolClass, NSString, NSArray;

// Defaults stuff
extern NSString *IRCDefaultsNick;
extern NSString *IRCDefaultsRealName;
extern NSString *IRCDefaultsUserName;
extern NSString *IRCDefaultsPassword;

// Attributed string stuff

#ifdef S2AS
	#undef S2AS
#endif

#define S2AS(_x) AUTORELEASE([[NSAttributedString alloc] initWithString: \
                   (_x)])

// Key
extern NSString *IRCColor;
extern NSString *IRCBackgroundColor;
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
extern NSString *IRCColorCustom;

// Keys
extern NSString *IRCBold;
extern NSString *IRCUnderline;


#ifndef TALKSOUP_H
#define TALKSOUP_H

#include <Foundation/NSObject.h>

#include "TalkSoupProtocols.h"
#include "TalkSoupMisc.h"

@class NSInvocation, NSString, NSMutableDictionary, NSMutableArray;

extern id _TS_;
extern id _TSDummy_;

@interface TalkSoup : NSObject
	{
		NSMutableDictionary *inputNames;
		NSString *activatedInput;
		id input;

		NSMutableDictionary *outputNames;
		NSString *activatedOutput;
		id output;
		
		NSMutableDictionary *inNames;
		NSMutableArray *activatedInFilters;
		NSMutableDictionary *inObjects;
		
		NSMutableDictionary *outNames;
		NSMutableArray *activatedOutFilters;
		NSMutableDictionary *outObjects;
				
		NSMutableDictionary *commandList;
	}
+ (TalkSoup *)sharedInstance;

- (void)setupCommandList;
- (void)refreshPluginList;

- (NSInvocation *)invocationForCommand: (NSString *)aCommand;
- addCommand: (NSString *)aCommand withInvocation: (NSInvocation *)invoc;
- removeCommand: (NSString *)aCommand;
- (NSArray *)allCommands;

- (NSString *)input;
- (NSString *)output;
- (NSDictionary *)allInputs;
- (NSDictionary *)allOutputs;
- setInput: (NSString *)aInput;
- setOutput: (NSString *)aOutput;

- (NSArray *)activatedInFilters;
- (NSArray *)activatedOutFilters;
- (NSDictionary *)allInFilters;
- (NSDictionary *)allOutFilters;

- activateInFilter: (NSString *)aFilt;
- activateOutFilter: (NSString *)aFilt;
- deactivateInFilter: (NSString *)aFilt;
- deactivateOutFilter: (NSString *)aFilt;
- setActivatedInFilters: (NSArray *)filters;
- setActivatedOutFilters: (NSArray *)filters;

- (id)pluginForOutput;
- (id)pluginForOutFilter: (NSString *)aFilt;
- (id)pluginForInFilter: (NSString *)aFilt;
- (id)pluginForInput;
@end
  
#endif
