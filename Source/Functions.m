/***************************************************************************
                                Functions.m
                          -------------------
    begin                : Sat Apr  5 22:21:33 CST 2003
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

#include "TalkSoup.h"
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSNull.h>

#include <stdarg.h>

static NSDictionary *mappings = nil;

static void build_mappings(void)
{
	RELEASE(mappings);
	mappings = RETAIN(([NSDictionary dictionaryWithObjectsAndKeys:
	  IRCColorWhite, @"white",
	  IRCColorBlack, @"black",
	  IRCColorBlue, @"blue",
	  IRCColorGreen, @"green",
	  IRCColorRed, @"red",
	  IRCColorMaroon, @"maroon", 
	  IRCColorMagenta, @"magenta",
	  IRCColorOrange, @"orange",
	  IRCColorYellow, @"yellow",
	  IRCColorLightGreen, @"light green",
	  IRCColorTeal, @"teal",
	  IRCColorLightCyan, @"light cyan",
	  IRCColorLightBlue, @"light blue",
	  IRCColorLightMagenta, @"light magenta",
	  IRCColorLightGrey, @"light grey",
	  IRCColorGrey, @"grey", nil]));
}

NSString *IRCColorFromUserColor(NSString *string)
{
	id x;
	if (!mappings) build_mappings();

	string = [string lowercaseString];	
	x = [mappings objectForKey: string];
	
	if ([string hasPrefix: @"custom"])
	{
		int r,g,b;
		id scan;
		
		scan = [NSScanner scannerWithString: string];
		[scan scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
		  intoString: 0];
		
		[scan scanInt: &r];
		[scan scanInt: &g];
		[scan scanInt: &b];
		
		r = r % 1001;
		g = g % 1001;
		b = b % 1001;
		
		return [NSString stringWithFormat: @"IRCColorCustom %d %d %d",
		  r, g, b];
	}
	
	return x;
}

NSArray *PossibleUserColors(void)
{
	if (!mappings) build_mappings();

	return [mappings allKeys];
}
	
static NSArray *get_first_word(NSString *arg)
{
	NSRange aRange;
	NSString *first, *rest;
	id white = [NSCharacterSet whitespaceCharacterSet];

	arg = [arg stringByTrimmingCharactersInSet: white];
	  
	if ([arg length] == 0)
	{
		return [NSArray arrayWithObjects: nil];
	}

	aRange = [arg rangeOfCharacterFromSet: white];

	if (aRange.location == NSNotFound && aRange.length == 0)
	{
		return [NSArray arrayWithObjects: arg, nil];
	}
	
	rest = [[arg substringFromIndex: aRange.location]
	  stringByTrimmingCharactersInSet: white];
	
	first = [arg substringToIndex: aRange.location];

	return [NSArray arrayWithObjects: first, rest, nil];
}

@implementation NSString (Separation)
- separateIntoNumberOfArguments: (int)num
{
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);
	id object;
        int temp;
        id string = self;
	
	if (num <= 1)
	{
		return [NSArray arrayWithObject: [string 
		  stringByTrimmingCharactersInSet: 
		    [NSCharacterSet whitespaceCharacterSet]]];
	}
	if (num == 2)
	{
		return get_first_word(string);
	}
	
	while (num != 1)
	{
		object = get_first_word(string);
		temp = [object count];
		switch(temp)
		{
			case 0:
				return [NSArray arrayWithObjects: nil];
			case 1:
				[array addObject: [object objectAtIndex: 0]];
				return array;
			case 2:
				string = [object objectAtIndex: 1];
				[array addObject: [object objectAtIndex: 0]];
				num--;
		}
	}
	[array addObject: string];
	return array;
}
@end

@implementation NSMutableAttributedString (AttributesAppend)
- (void)addAttributeIfNotPresent: (NSString *)name value: (id)aVal
   withRange: (NSRange)aRange
{
	NSRange effect;
	NSDictionary *aDict;
	NSMutableDictionary *aDict2;
	
	[self beginEditing];
	
	aDict = [self attributesAtIndex: aRange.location effectiveRange: &effect];
	
	while (1)
	{
		if (![aDict objectForKey: name])
		{
			if (effect.location + effect.length > aRange.location + aRange.length)
			{
				effect.length = aRange.location + aRange.length - effect.location;
			}
				
			aDict2 = [NSMutableDictionary dictionaryWithDictionary: aDict];
			[aDict2 setObject: aVal forKey: name];
			[self setAttributes: aDict2 range: effect];
		}
		effect.location = effect.location + effect.length;
		if (effect.location < aRange.length + aRange.location)
		{
			aDict = [self attributesAtIndex: effect.location 
			  effectiveRange: &effect];
		}
		else
		{
			break;
		}
	}
	
	[self endEditing];
}
- (void)replaceAttribute: (NSString *)name withValue: (id)aVal
   withValue: (id)newVal withRange: (NSRange)aRange
{
	NSRange effect;
	NSDictionary *aDict;
	NSMutableDictionary *aDict2;
	
	[self beginEditing];
	
	aDict = [self attributesAtIndex: aRange.location effectiveRange: &effect];
	
	while (1)
	{
		if ([[aDict objectForKey: name] isEqual: aVal])
		{
			if (effect.location + effect.length > aRange.location + aRange.length)
			{
				effect.length = aRange.location + aRange.length - effect.location;
			}
				
			aDict2 = [NSMutableDictionary dictionaryWithDictionary: aDict];
			[aDict2 setObject: newVal forKey: name];
			[self setAttributes: aDict2 range: effect];
		}
			
		effect.location = effect.location + effect.length;
		if (effect.location < aRange.length + aRange.location)
		{
			aDict = [self attributesAtIndex: effect.location 
			  effectiveRange: &effect];
		}
		else
		{
			break;
		}
	}
	
	[self endEditing];
}
- (void)replaceAttribute: (NSString *)name withExactValue: (id)aVal
   withValue: (id)newVal withRange: (NSRange)aRange
{
	NSRange effect;
	NSDictionary *aDict;
	NSMutableDictionary *aDict2;
	
	[self beginEditing];
	
	aDict = [self attributesAtIndex: aRange.location effectiveRange: &effect];
	
	while (1)
	{
		if ([aDict objectForKey: name] == aVal)
		{
			if (effect.location + effect.length > aRange.location + aRange.length)
			{
				effect.length = aRange.location + aRange.length - effect.location;
			}
				
			aDict2 = [NSMutableDictionary dictionaryWithDictionary: aDict];
			[aDict2 setObject: newVal forKey: name];
			[self setAttributes: aDict2 range: effect];
		}
			
		effect.location = effect.location + effect.length;
		if (effect.location < aRange.length + aRange.location)
		{
			aDict = [self attributesAtIndex: effect.location 
			  effectiveRange: &effect];
		}
		else
		{
			break;
		}
	}
	
	[self endEditing];
}
@end

NSMutableAttributedString *BuildAttributedString(id aObject, ...)
{
	va_list ap;
	NSMutableAttributedString *str;
	id objects;
	id keys;
	int state = 0;
	id newstr = nil;
	int x;
	int y;
	
	if (aObject == nil) return 
	  AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @""]);
	
	objects = [NSMutableArray new];
	keys = [NSMutableArray new];
	
	str = AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @""]);
	va_start(ap, aObject);
	
	do
	{
		if (state != 0)
		{
			if (state == 1)
			{
				[keys addObject: aObject];
				state = 2;
			}
			else if (state == 2)
			{
				[objects addObject: aObject];
				state = 0;
			}
		}
		else
		{
			if ([aObject isKindOf: [NSNull class]])
			{
				state = 1;
			}
			else
			{
				if ([aObject isKindOf: [NSAttributedString class]])
				{
					newstr = [[NSMutableAttributedString alloc] 
					  initWithAttributedString: aObject];
				}
				else
				{
					newstr = [[NSMutableAttributedString 
					  alloc] initWithString: [aObject description]];
				}
				
				if (newstr)
				{
					y = [objects count];
					for (x = 0; x < y; x++)
					{
						[newstr addAttributeIfNotPresent: [keys objectAtIndex: x]
						  value: [objects objectAtIndex: x] withRange:
						   NSMakeRange(0, [newstr length])];
					}
					[objects removeAllObjects];
					[keys removeAllObjects];
					[str appendAttributedString: newstr];
					DESTROY(newstr);
				}
			}
		}
	} while ((aObject = va_arg(ap, id)));

	va_end(ap);
	RELEASE(objects);
	RELEASE(keys);
	
	return str;
}

NSMutableAttributedString *BuildAttributedFormat(id aObject, ...)
{
	va_list ap;
	NSMutableAttributedString *str;
	NSString *format;
	NSRange range;
	NSRange tmpr;
	int len;
	id tmp = nil;
	
	str = AUTORELEASE([[NSMutableAttributedString alloc] initWithString: @""]);

	if (aObject == nil) return str;

	if ([aObject isKindOf: [NSString class]])
	{
		aObject = AUTORELEASE([[NSAttributedString alloc] 
		  initWithString: aObject]);
	}
	else if (![aObject isKindOf: [NSAttributedString class]])
	{
		return str;
	}	
	
	va_start(ap, aObject);
	
	format = [aObject string];
	range.location = 0;
	range.length = len = [format length];
	
	while (range.location < len)
	{
		tmpr = [format rangeOfString: @"%@" options: 0 range: range];
		
		if (tmpr.location == NSNotFound)
		{
			[str appendAttributedString: [aObject attributedSubstringFromRange: range]];
			return str;
		}
		else
		{
			NSRange oldRange = range;
			
			range.location = tmpr.location + 2;
			range.length = len - range.location;
			
			tmpr.length = tmpr.location - oldRange.location;
			tmpr.location = oldRange.location;
			
			[str appendAttributedString: [aObject attributedSubstringFromRange: tmpr]];
			tmp = va_arg(ap, id);
			if ([tmp isKindOf: [NSString class]])
			{
				tmp = AUTORELEASE([[NSAttributedString alloc] initWithString:
				  tmp]);
			}
			else if (![tmp isKindOf: [NSAttributedString class]])
			{
				tmp = AUTORELEASE([[NSAttributedString alloc] initWithString:
				  [tmp description]]);
			}
			
			[str appendAttributedString: tmp];
		}
	}	
	va_end(ap);
	
	return str;
}

NSArray *IRCUserComponents(NSAttributedString *from)
{
	NSArray *components = [[from string] componentsSeparatedByString: @"!"];
	NSAttributedString *string1, *string2;
	NSRange aRange = {0, 0};
	
	if (from)
	{	
		aRange.location = 0;
		aRange.length = [[components objectAtIndex: 0] length];
	
		string1 = [from attributedSubstringFromRange: aRange];
	
		aRange.location = aRange.length + 1;
	}
	else
	{
		string1 = AUTORELEASE([[NSAttributedString alloc] initWithString: @""]);
	}
	
	if (((int)[from length] - (int)aRange.location) <= 0)
	{
		string2 = AUTORELEASE([[NSAttributedString alloc] initWithString: @""]);
	}
	else
	{
		aRange.length = [from length] - aRange.length - 1;
		string2 = [from attributedSubstringFromRange: aRange];
	}
	
	return [NSArray arrayWithObjects: string1, string2, nil];
}
