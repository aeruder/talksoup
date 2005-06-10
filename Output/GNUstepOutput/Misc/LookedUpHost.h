/***************************************************************************
                             LookedUpHost.h
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

@class LookedUpHost;

#ifndef LOOKED_UP_HOST_H
#define LOOKED_UP_HOST_H

#import <Foundation/NSHost.h>

/* Basically this class is a thin wrapper around NSHost that allows us
 * to specify that we already know the host and the address, but we
 * just want the NSHost interface.
 */

@class NSString;

@interface NSHost (LookedUpHostAdditions)
+ (NSHost *)hostWithName: (NSString *)aName address: (NSString *)aAddress;
@end

@interface LookedUpHost : NSHost
	{
		NSString *hostName;
		NSString *address;
	}
@end

#endif
