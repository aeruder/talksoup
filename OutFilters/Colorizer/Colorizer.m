/***************************************************************************
                              Colorizer.m
                          -------------------
    begin                : Sat May 10 18:58:30 CDT 2003
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

#import "Colorizer.h"
#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAttributedString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>

#include <ctype.h>

static inline BOOL scan_two_char_int(NSScanner *beg, int *aInt)
{
	// FIXME this needs to be highly optimized
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
	
	if (!isdigit([two characterAtIndex: 0])) return NO;
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
static NSCharacterSet *reverse_control = nil;
static NSString *colors[16] = { 0 };
	
static void initialize_stuff(void)
{
	CREATE_AUTORELEASE_POOL(apr);
	
	comma = RETAIN([NSCharacterSet characterSetWithCharactersInString: @","]);
	color_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"C"]);
	bold_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"B"]);
	underline_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"U"]);
	clear_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"O"]);
	reverse_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"R"]);	
	control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: 
	   @"%"]);
	
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

static inline NSAttributedString *as2cas(NSAttributedString *astr)
{
	NSScanner *scan;
	id aString;
	int x;
	NSMutableAttributedString *string = 
	  AUTORELEASE([NSMutableAttributedString new]);
	NSMutableDictionary *dict = AUTORELEASE([NSMutableDictionary new]);
	id str = [astr string];
	int location;

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
		location = [scan scanLocation];
		if ([scan scanUpToCharactersFromSet: control intoString: &aString])
		{
			NSRange aRange;
			aRange = NSMakeRange(location, [aString length]);
			
			aString = [astr attributedSubstringFromRange: aRange];
			
			aRange.location = [string length];
			[string appendAttributedString: aString];
			[string addAttributes: [NSDictionary dictionaryWithDictionary: dict]
			  range: aRange];
		}
		
		if ([scan isAtEnd] == YES) break;		
		[scan setScanLocation: [scan scanLocation] + 1];
		if ([scan isAtEnd] == YES)
		{
			[string appendAttributedString:
			  AUTORELEASE([[NSAttributedString alloc] initWithString: @"%"
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];

			break;
		}
		
		if (scan_one_char_from_set(scan, control, 0))
		{
			[string appendAttributedString: 
			  AUTORELEASE([[NSAttributedString alloc] initWithString: @"%"
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];
		}
		else if (scan_one_char_from_set(scan, bold_control, 0))
		{
			if (![dict objectForKey: IRCBold])
			{
				[dict setObject: IRCBoldValue
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
				[dict setObject: IRCUnderlineValue
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
		else if (scan_one_char_from_set(scan, reverse_control, 0))
		{
			if (![dict objectForKey: IRCReverse])
			{
				[dict setObject: IRCReverseValue
				  forKey: IRCReverse];
			}
			else
			{
				[dict removeObjectForKey: IRCReverse];
			}
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
		}
		else
		{
			[string appendAttributedString:
			  AUTORELEASE([[NSAttributedString alloc] initWithString: @"%"
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];
		}
	}
	
	return string;
}		

@implementation Colorizer
- (NSAttributedString *)pluginDescription
{
	return BuildAttributedString([NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Author: "), @"Andrew Ruder\n\n",
	 [NSNull null], IRCBold, IRCBoldValue,
	 _l(@"Description: "), _l(@"Adds color into outgoing messages. "
	 @"The syntax is %C#[,#] for colors.  The first # specifies "
	 @"the foreground color and the second # specifies the "
	 @"optional second color.  The colors are in the range of "
	 @"0-15\n"),
	 _l(@"Bold is %B, underline is %U, and %R is reverse.  Repeating "
	 @"any one of these a second time will result in the turning "
	 @"off of that attribute.  Use %O to clear all colors and "
	 @"attributes."),
	 @"\n\n",
	 _l(@"Copyright (C) 2005 by Andrew Ruder"),
	 nil);
}
- quitWithMessage: (NSAttributedString *)aMessage onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ quitWithMessage: as2cas(aMessage) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- partChannel: (NSAttributedString *)channel 
   withMessage: (NSAttributedString *)aMessage 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ partChannel: channel withMessage: as2cas(aMessage)
	  onConnection: aConnection withNickname: aNick
	  sender: self];
	return self;
}
- sendCTCPReply: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendCTCPReply: aCTCP withArgument: as2cas(args)
	 to: aPerson onConnection: aConnection withNickname: aNick
	 sender: self];
	return self;
}
- sendCTCPRequest: (NSAttributedString *)aCTCP 
   withArgument: (NSAttributedString *)args
   to: (NSAttributedString *)aPerson onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ sendCTCPRequest: aCTCP
	  withArgument: as2cas(args) to: aPerson
	  onConnection: aConnection
	  withNickname: aNick
	  sender: self];
	return self;
} 
- sendMessage: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick    
	sender: aPlugin
{
	[_TS_ sendMessage: as2cas(message) to: receiver
	  onConnection: aConnection withNickname: aNick
	  sender: self];
	return self;
}
- sendNotice: (NSAttributedString *)message to: (NSAttributedString *)receiver 
   onConnection: aConnection
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ sendNotice: as2cas(message) to: receiver
	 onConnection: aConnection withNickname: aNick
	 sender: self];
	return self;
}
- sendAction: (NSAttributedString *)anAction to: (NSAttributedString *)receiver 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
	sender: aPlugin
{
	[_TS_ sendAction: as2cas(anAction) to: receiver
	 onConnection: aConnection
	 withNickname: aNick
	 sender: self];
	return self;
}
- sendWallops: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendWallops: as2cas(message) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- setTopicForChannel: (NSAttributedString *)aChannel 
   to: (NSAttributedString *)aTopic 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ setTopicForChannel: aChannel to: as2cas(aTopic) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- kick: (NSAttributedString *)aPerson offOf: (NSAttributedString *)aChannel 
   for: (NSAttributedString *)reason 
   onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ kick: aPerson offOf: aChannel for: as2cas(reason) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
- setAwayWithMessage: (NSAttributedString *)message onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ setAwayWithMessage: as2cas(message) onConnection: aConnection
	  withNickname: aNick sender: self];
	return self;
}
@end


