/***************************************************************************
                                NSAttributedStringAdditions.m
                          -------------------
    begin                : Mon Apr 28 06:48:06 CDT 2003
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
 
#include "Misc/NSAttributedStringAdditions.h"

#include "TalkSoupBundles/TalkSoup.h"

#include <AppKit/NSColor.h>
#include <AppKit/NSAttributedString.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>

static inline NSColor *map_color(NSString *aName)
{
	static NSDictionary *colors = nil;
	
	if (!colors)
	{
	colors = RETAIN(([NSDictionary dictionaryWithObjectsAndKeys:
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 1.0 blue: 1.0 alpha: 1.0], IRCColorWhite, 
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 0.0 blue: 0.0 alpha: 1.0], IRCColorBlack,
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 0.0 blue: 1.0 alpha: 1.0], IRCColorBlue,
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 1.0 blue: 0.0 alpha: 1.0], IRCColorGreen,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 0.0 blue: 0.0 alpha: 1.0], IRCColorRed,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 0.0 blue: 0.0 alpha: 1.0], IRCColorMaroon,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 0.0 blue: 0.5 alpha: 1.0], IRCColorMagenta,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 0.7 blue: 0.0 alpha: 1.0], IRCColorOrange,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 1.0 blue: 0.0 alpha: 1.0], IRCColorYellow,
	  [NSColor colorWithCalibratedRed: 0.6
	                green: 0.9 blue: 0.6 alpha: 1.0], IRCColorLightGreen,
	  [NSColor colorWithCalibratedRed: 0.0
	                green: 0.5 blue: 0.5 alpha: 1.0], IRCColorTeal,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 1.0 blue: 1.0 alpha: 1.0], IRCColorLightCyan,
	  [NSColor colorWithCalibratedRed: 0.7
	                green: 0.8 blue: 0.9 alpha: 1.0], IRCColorLightBlue,
	  [NSColor colorWithCalibratedRed: 1.0
	                green: 0.75 blue: 0.75 alpha: 1.0], IRCColorLightMagenta,
	  [NSColor colorWithCalibratedRed: 0.5
	                green: 0.5 blue: 0.5 alpha: 1.0], IRCColorGrey,
	  [NSColor colorWithCalibratedRed: 0.8
	                green: 0.8 blue: 0.8 alpha: 1.0], IRCColorLightGrey,
	  nil]));
	}
	  
	return [colors objectForKey: aName];
}

@implementation NSAttributedString (OutputAdditions)	  
- (NSMutableAttributedString *)substituteColorCodesIntoAttributedString
{
	NSMutableAttributedString *a = AUTORELEASE([NSMutableAttributedString new]);
	NSRange all =  { 0 };
	NSRange work =  { 0 };
	int len = [self length];
	NSMutableDictionary *dict;
	id obj;
	
	all.length = len;
	
	while (all.length > 0)
	{
		dict = [NSMutableDictionary dictionaryWithDictionary: 
		 [self attributesAtIndex: all.location longestEffectiveRange: &work
		 inRange: all]];
		if ((obj = [dict objectForKey: IRCColor]))
		{
			if (![dict objectForKey: NSForegroundColorAttributeName])
			{
				[dict setObject: map_color(obj) forKey: NSForegroundColorAttributeName];
			}
		}
		if ((obj = [dict objectForKey: IRCBackgroundColor]))
		{
			if (![dict objectForKey: NSBackgroundColorAttributeName])
			{
				[dict setObject: map_color(obj) forKey: NSBackgroundColorAttributeName];
			}
		}
		if ([dict objectForKey: IRCUnderline])
		{
			[dict setObject: [NSNumber numberWithInt: 1] 
			  forKey: NSUnderlineStyleAttributeName];
		}
		if ([dict objectForKey: IRCBold])
		{
			[dict setObject: [NSFont boldSystemFontOfSize: 12.0]
			  forKey: NSFontAttributeName];
		}
	
		[a appendAttributedString: AUTORELEASE([[NSAttributedString alloc]
		  initWithString: [[self string] substringWithRange: work] attributes: dict])];
		all.location = work.location + work.length;
		all.length = len - all.location;
	}
	
	return a;
}
@end

