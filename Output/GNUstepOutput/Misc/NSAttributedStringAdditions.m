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
#include "Misc/NSColorAdditions.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <AppKit/NSColor.h>
#include <AppKit/NSAttributedString.h>
#include <Foundation/NSValue.h>
#include <Foundation/NSString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSScanner.h>

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
				id temp;
				temp = [NSColor colorFromIRCString: obj];
				if (temp)
				{
					[dict setObject: temp forKey: NSForegroundColorAttributeName];
				}
			}
		}
		if ((obj = [dict objectForKey: IRCBackgroundColor]))
		{
			if (![dict objectForKey: NSBackgroundColorAttributeName])
			{
				id temp;
				temp = [NSColor colorFromIRCString: obj];
				if (temp)
				{
					[dict setObject: temp forKey: NSBackgroundColorAttributeName];
				}
			}
		}
		if ([dict objectForKey: IRCUnderline])
		{
			[dict setObject: [NSNumber numberWithInt: 1] 
			  forKey: NSUnderlineStyleAttributeName];
		}
		if ([dict objectForKey: IRCBold])
		{
			[dict setObject: [NSFont boldSystemFontOfSize: 0.0]
			  forKey: NSFontAttributeName];
		}
		else
		{
			[dict setObject: [NSFont userFontOfSize: 0.0]
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

