/***************************************************************************
                              Colorizer.m
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

#include "Colorizer.h"
#include "TalkSoupBundles/TalkSoup.h"

#include <Foundation/NSAttributedString.h>
#include <Foundation/NSNull.h>
#include <Foundation/NSCharacterSet.h>
#include <Foundation/NSScanner.h>
#include <Foundation/NSAutoreleasePool.h>

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
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"C"]);
	bold_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"B"]);
	underline_control = 
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"U"]);
	clear_control =
	  RETAIN([NSCharacterSet characterSetWithCharactersInString: @"O"]);
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
			
			aString = [astr attributedSubstringWithRange: aRange];
			
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
		
		if ([scan scanCharactersFromSet: control intoString: 0])
		{
			[string appendAttributedString: 
			  AUTORELEASE([[NSAttributedString alloc] initWithString: @"%"
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];
		}
		else if ([scan scanCharactersFromSet: bold_control intoString: 0])
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
		else
		{
			[string appendAttributedString:
			  AUTORELEASE([[NSAttributedString alloc] initWithString: @"%"
			  attributes: [NSDictionary dictionaryWithDictionary: dict]])];
		}
	}
	
	return AUTORELEASE([[NSAttributedString alloc] initWithAttributedString:
	  string]);
}		

@implementation Colorizer
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
- sendPingWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendPingWithArgument: as2cas(aString) onConnection: aConnection
	 withNickname: aNick sender: self];
	return self;
}
- sendPongWithArgument: (NSAttributedString *)aString onConnection: aConnection 
   withNickname: (NSAttributedString *)aNick 
   sender: aPlugin
{
	[_TS_ sendPongWithArgument: as2cas(aString) onConnection: aConnection
	 withNickname: aNick sender: self];
	return self;
}
@end


