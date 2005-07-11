/***************************************************************************
                             LookedUpHost.m
                          -------------------
    begin                : Thu Jun  9 19:12:10 CDT 2005
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

#import "Misc/LookedUpHost.h"

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSObject.h>

@interface LookedUpHost (PrivateMethods)
- (void)setName: (NSString *)aName;
- (void)setAddress: (NSString *)aAddress;
@end

@implementation LookedUpHost (PrivateMethods)
- (void)setName: (NSString *)aName
{
	ASSIGN(hostName, aName);
}
- (void)setAddress: (NSString *)aAddress
{
	ASSIGN(address, aAddress);
}
@end

@implementation NSHost (LookedUpHostAdditions)
+ (NSHost *)hostWithName: (NSString *)aName address: (NSString *)aAddress
{
	id host;

	if (!aName && !aAddress) return nil;
	if (!aName)
	{
		return [NSHost hostWithAddress: aAddress];
	}
	if (!aAddress)
	{
		return [NSHost hostWithName: aName];
	}

	host = [LookedUpHost new];
	AUTORELEASE(host);
	[host setName: aName];
	[host setAddress: aAddress];

	return host;
}
@end

@implementation LookedUpHost
- init 
{
	/* Bypass parents init.  Ugly, but it should work. */
	IMP objInit;
	objInit = [NSObject instanceMethodForSelector: _cmd];

	if (!(self = objInit(self, _cmd))) 
		return nil;

	return self;
}
- (NSString *)address
{
	return address;
}
- (NSArray *)addresses
{
	return [NSArray arrayWithObject: address];
}
- (NSString *)name
{
	return hostName;
}
- (NSArray *)names
{
	return [NSArray arrayWithObject: hostName];
}
- (BOOL)isEqualToHost: (NSHost *)aHost
{
	return [[aHost addresses] containsObject: address];
}
- (void)dealloc
{
	/* Bypass parents dealloc.  Ugly, but it should work. */
	void (*objDealloc)(id, SEL);
	
	objDealloc = 
	  (void (*)(id, SEL))[NSObject instanceMethodForSelector: _cmd];

	RELEASE(address);
	RELEASE(hostName);

	objDealloc(self, _cmd);

	if (1) return;

	[super dealloc];
}
@end
