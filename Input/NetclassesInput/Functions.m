/***************************************************************************
                                Functions.m
                          -------------------
    begin                : Mon Apr 28 02:10:41 CDT 2003
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

#include <Foundation/NSScanner.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSAutoreleasePool.h>
#include "TalkSoupBundles/TalkSoup.h"

static inline BOOL scan_two_char_int(NSScanner *beg, int *aInt)
{
	int y;
	id string;
	id two;
	NSRange sub;
	id scan;
	
	string = [beg string];
	if (!string) return NO;

	sub.location = [beg scanLocation];
	sub.length = 2;
	
	if (sub.location == [string length]) return NO;

	if (sub.location == ([string length] - 1)) sub.length = 1;

	two = [string substringWithRange: sub];

	scan = [NSScanner scannerWithString: two];
	[scan setCharactersToBeSkipped: [NSCharacterSet 
	  characterSetWithCharactersInString: @""]];
	if (![scan scanInt: &y]) return NO;

	[beg setScanLocation: sub.location + [scan scanLocation]];

	if (aInt) *aInt = y;

	return YES;
}

static NSCharacterSet *comma = nil;
static NSCharacterSet *control = nil;
static NSCharacterSet *color_control = nil;
static NSCharacterSet *bold_control = nil;
static NSCharacterSet *underline_control = nil;
static NSCharacterSet *clear_control = nil;
static NSString *colors[16] = { 0 };
	
static void initialize_stuff(void)
{
	CREATE_AUTORELEASE_POOL(apr);
	
	comma = RETAIN([NSCharacterSet characterSetWithCharactersInString: @","]);
	color_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\003"]);
	bold_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\002"]);
	underline_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\037"]);
	clear_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"\017"]);
	control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: 
	   @"\003\002\037\017"]);
	
	colors[0] = RETAIN(IRCColorWhite);
	colors[1] = RETAIN(IRCColorBlack);
	colors[2] = RETAIN(IRCColorBlue);
	colors[3] = RETAIN(IRCColorGreen);
	colors[4] = RETAIN(IRCColorRed);
	colors[5] = RETAIN(IRCColorMaroon);
	colors[6] = RETAIN(IRCColorMagenta);
	colors[7] = RETAIN(IRCColorOrange);
	colors[8] = RETAIN(IRCColorYellow);
	colors[9] = RETAIN(IRCColorLightGreen);
	colors[10] = RETAIN(IRCColorTeal);
	colors[11] = RETAIN(IRCColorLightCyan);
	colors[12] = RETAIN(IRCColorLightBlue);
	colors[13] = RETAIN(IRCColorLightMagenta);
	colors[14] = RETAIN(IRCColorGrey);
	colors[15] = RETAIN(IRCColorLightGrey);
	
	RELEASE(apr);
}

inline NSAttributedString *NetClasses_AttributedStringFromString(NSString *str)
{
	NSScanner *scan;
	NSString *aString;
	int x;
	NSMutableAttributedString *string = 
	  AUTORELEASE([NSMutableAttributedString new]);
	NSMutableDictionary *dict = AUTORELEASE([NSMutableDictionary new]);

	if (!str)
	{
		return nil;
	}
	
	if (!comma)
	{
		initialize_stuff();
	}
	
	scan = [NSScanner scannerWithString: str];
	[scan setCharactersToBeSkipped: [NSCharacterSet 
	  characterSetWithCharactersInString: @""]];
	
	while ([scan isAtEnd] == NO)
	{
		if ([scan scanUpToCharactersFromSet: control intoString: &aString])
		{
			[string appendAttributedString: 
			  AUTORELEASE([[NSAttributedString alloc] initWithString: aString
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];
		}
		
		if ([scan isAtEnd] == YES) break;
		
		if ([scan scanCharactersFromSet: bold_control intoString: 0])
		{
			if (![dict objectForKey: IRCBold])
			{
				[dict setObject: [NSNull null]
				  forKey: IRCBold];
			}
			else
			{
				[dict removeObjectForKey: IRCBold];
			}
		}
		else if ([scan scanCharactersFromSet: underline_control intoString: 0])
		{
			if (![dict objectForKey: IRCUnderline])
			{
				[dict setObject: [NSNull null]
				  forKey: IRCUnderline];
			}
			else
			{
				[dict removeObjectForKey: IRCUnderline];
			}
		}
		else if ([scan scanCharactersFromSet: clear_control intoString: 0])
		{
			[dict removeAllObjects];
		}
		else if ([scan scanCharactersFromSet: color_control intoString: 0])
		{
			if (scan_two_char_int(scan, &x))
			{
				x = x % 16;
				[dict setObject: colors[x] forKey: 
				  IRCColor];
	
				if ([scan scanCharactersFromSet: comma intoString: 0])
				{
					if (scan_two_char_int(scan, &x))
					{
						x = x % 16;
						[dict setObject: colors[x] forKey:
						  IRCBackgroundColor];
					}
				}	
			}
			else if ([scan scanCharactersFromSet: comma intoString: 0])
			{
				if (scan_two_char_int(scan, &x))
				{
					x = x % 16;
					[dict setObject: colors[x] forKey:
					  IRCBackgroundColor];
				}
			}
			else
			{
				[dict removeObjectForKey: IRCBackgroundColor];
				[dict removeObjectForKey: IRCColor];
			}
		}	
	}
	
	return AUTORELEASE([[NSAttributedString alloc] initWithAttributedString:
	  string]);
}		

static inline NSString *lookup_color(NSString *aString)
{
	int x;
	
	for (x = 0; x < 16; x++)
	{
		if ([colors[x] isEqualToString: aString])
		{
			return [NSString stringWithFormat: @"%02d", x];
		}
	}
	
	return @"";
}

inline NSString *NetClasses_StringFromAttributedString(NSAttributedString *atr)
{
	NSRange cur = {0, 0};
	NSRange work;
	NSDictionary *b;
	NSDictionary *so = AUTORELEASE([NSDictionary new]);
	id begF;
	id begB;
	id nowF = nil;
	id nowB = nil;
	NSMutableString *aString = [NSMutableString new];
	int len = [atr length];
	
	cur.length = len;
	
	while (cur.length > 0)
	{
		b = [atr attributesAtIndex: cur.location 
		     longestEffectiveRange: &work inRange: cur];
		
		begB = [b objectForKey: IRCBold];
		begF = [so objectForKey: IRCBold];
		if (begB != begF && [begB isEqual: begF])
		{
			[aString appendString: @"\002"];
		}
		begB = [b objectForKey: IRCUnderline];
		begF = [so objectForKey: IRCUnderline];
		if (begB != begF && [begB isEqual: begF])
		{
			[aString appendString: @"\037"];
		}
		
		begF = nowF;
		begB = nowB;
		nowF = [b objectForKey: IRCColor];
		nowB = [b objectForKey: IRCBackgroundColor];
		
		if (!nowF && begF)
		{
			[aString appendString: @"\003"];
			if (nowB)
			{
				[aString appendString: @"\003,"];
				[aString appendString: lookup_color(nowB)];
			}
		}
		if (!nowB && begB)
		{
			[aString appendString: @"\003"];
			if (nowF)
			{
				[aString appendString: @"\003"];
				[aString appendString: lookup_color(nowF)];
			}
		}
		
		if (nowF && !begF)
		{
			[aString appendString: @"\003"];
			[aString appendString: lookup_color(nowF)];
			if (nowB)
			{
				[aString appendString: @","];
				[aString appendString: lookup_color(nowB)];
			}
		}
		
		if (nowB && !begB)
		{
			[aString appendString: @"\003"];
			if (nowF)
			{
				[aString appendString: lookup_color(nowF)];
			}
			[aString appendString: @","];
			[aString appendString: lookup_color(nowB)];
		}
		
		if (![nowF isEqual: begF] && nowF)
		{
			[aString appendString: @"\003"];
			[aString appendString: lookup_color(nowF)];
			if (![begB isEqual: nowB] && nowB)
			{
				[aString appendString: @","];
				[aString appendString: lookup_color(nowB)];
			}
		}
		else if (![nowB isEqual: begB] && nowB)
		{
			[aString appendString: @"\003,"];
			[aString appendString: lookup_color(nowB)];
		}
	
		[aString appendString: [[atr string] substringWithRange: work]];
		cur.location = work.location + work.length;
		cur.length = len - cur.length; 
		
		so = b;
	}

	return AUTORELEASE(aString);
}

