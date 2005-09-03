/***************************************************************************
                                Encodings.m
                          -------------------
    begin                : Sat Sep  3 15:18:19 CDT 2005
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

#import "Encodings.h"

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>

static inline NSString *identifierForEncoding(NSStringEncoding encoding)
{
	return [NSString stringWithFormat: @"%u", (unsigned)encoding];
}

static inline NSStringEncoding encodingForIdentifier(NSString *ident)
{
	unsigned ret;
	
	sscanf([ident cStringUsingEncoding: NSASCIIStringEncoding], "%u", &ret);

	return (NSStringEncoding)ret;
}

@implementation TalkSoup (Encodings)
- (NSStringEncoding)encodingForName: (NSString *)aName
{
	const NSStringEncoding *iter = [NSString availableStringEncodings];

	for (; *iter; iter++)
	{
		if ([aName isEqualToString: [NSString localizedNameOfStringEncoding: *iter]])
			return *iter;
	}

	return 0;
}
- (NSString *)nameForEncoding: (NSStringEncoding)aEncoding
{
	return [NSString localizedNameOfStringEncoding: aEncoding];
}
- (NSArray *)allEncodingNames
{
	const NSStringEncoding *iter = [NSString availableStringEncodings];
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);

	for (; *iter; iter++)
	{
		[array addObject: [NSString localizedNameOfStringEncoding: *iter]];
	}

	return [NSArray arrayWithArray: array];
}
- (NSArray *)allEncodingIdentifiers
{
	const NSStringEncoding *iter = [NSString availableStringEncodings];
	NSMutableArray *array = AUTORELEASE([NSMutableArray new]);

	for (; *iter; iter++)
	{
		[array addObject: identifierForEncoding(*iter)];
	}

	return [NSArray arrayWithArray: array];
}

- (const NSStringEncoding *)allEncodings
{
	return [NSString availableStringEncodings];
}
- (NSString *)identifierForEncoding: (NSStringEncoding)aEncoding
{
	return identifierForEncoding(aEncoding);
}
- (NSStringEncoding)encodingForIdentifier: (NSString *)aIdentifier
{
	return encodingForIdentifier(aIdentifier);
}
@end
