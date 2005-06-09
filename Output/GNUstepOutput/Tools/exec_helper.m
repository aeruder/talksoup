/***************************************************************************
                             exec_helper.m 
                          -------------------
    begin                : Wed Jun  8 20:55:48 CDT 2005
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

/* This is a simple tool that handles the problem of execing a separate task
 * without having to worry about the exec'd task hanging, using lots of 
 * cpu, running forever, etc...
 */

#import <TalkSoupBundles/TalkSoup.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSRunLoop.h>

int main(int argc, char **argv, char **env)
{
	CREATE_AUTORELEASE_POOL(apr);

	[[NSRunLoop currentRunLoop] run];
	
	RELEASE(apr);
	return 0;
}
