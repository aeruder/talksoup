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

static inline BOOL scan_one_char_from_set(NSScanner *beg, NSCharacterSet *aSet, NSString **y)
{
	unichar x;
	int pos;
	
	if ([beg isAtEnd]) return NO;
	
	pos = [beg scanLocation];
	
	x = [[beg string] characterAtIndex: pos];
	
	if (![aSet characterIsMember: x]) return NO;

	if (y) *y = [NSString stringWithCharacters: &x length: 1];
	
	[beg setScanLocation: pos + 1];
	
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
		
		if (scan_one_char_from_set(scan, bold_control, 0))
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
		else if (scan_one_char_from_set(scan, underline_control, 0))
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
		else if (scan_one_char_from_set(scan, clear_control, 0))
		{
			[dict removeAllObjects];
		}
		else if (scan_one_char_from_set(scan, color_control, 0))
		{
			if (scan_two_char_int(scan, &x))
			{
				x = x % 16;
				[dict setObject: colors[x] forKey: 
				  IRCColor];
				if (scan_one_char_from_set(scan, comma, 0))
				{
					NSLog(@"Found a background with foreground...");
					if (scan_two_char_int(scan, &x))
					{
						x = x % 16;
						[dict setObject: colors[x] forKey:
						  IRCBackgroundColor];
					}
				}	
			}
			else if (scan_one_char_from_set(scan, comma, 0))
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
			NSLog(@"Current dict: %@", dict);
		}	
	}
	
	return string;
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
	id nowF = @"";
	id nowB = @"";
	NSMutableString *aString = [NSMutableString new];
	int len = [atr length];
	
	cur.length = len;
	
	while (cur.length > 0)
	{
		b = [atr attributesAtIndex: cur.location 
		     longestEffectiveRange: &work inRange: cur];
		
		begB = [b objectForKey: IRCBold];
		begF = [so objectForKey: IRCBold];
		if ((!begB || !begF) && (begF || begB))
		{
			[aString appendString: @"\002"];
		}
		begB = [b objectForKey: IRCUnderline];
		begF = [so objectForKey: IRCUnderline];
		if ((!begB || !begF) && (begF || begB))
		{
			[aString appendString: @"\037"];
		}
		
		begF = nowF;
		begB = nowB;
		nowF = [b objectForKey: IRCColor];
		nowB = [b objectForKey: IRCBackgroundColor];
		
		if (!nowF) nowF = @"";
		if (!nowB) nowB = @"";
		
		if (![nowF isEqualToString: begF] && ![nowB isEqualToString: begB])
		{
			[aString appendString: @"\003"];
			if ([nowB length] > 0 && [nowF length] > 0)
			{
				[aString appendString: [NSString stringWithFormat: @"%@,%@",
				 lookup_color(nowF), lookup_color(nowB)]];
			}
			else if ([nowB length] > 0)
			{
				[aString appendString: [NSString stringWithFormat: @"\003,%@",
				  lookup_color(nowB)]];
			}
			else if ([nowF length] > 0)
			{
				[aString appendString: lookup_color(nowF)];
			}
		}
		else if (![nowF isEqualToString: begF])
		{
			[aString appendString: @"\003"];
			[aString appendString: lookup_color(nowF)];
		}
		else if (![nowB isEqualToString: begB])
		{
			[aString appendString: @"\003"];
			if ([nowB length] > 0)
			{
				[aString appendString: [NSString stringWithFormat: @",%@",
				  lookup_color(nowB)]];
			}
			else if ([nowF length] > 0)
			{
				[aString appendString: [NSString stringWithFormat: @"\003%@",
				  lookup_color(nowF)]];
			}
		}
		
		[aString appendString: [[atr string] substringWithRange: work]];
		cur.location = work.location + work.length;
		
		if (len <= cur.location) break;	
		cur.length = len - cur.location; 
		
		so = b;
	}
	
	return AUTORELEASE(aString);
}

