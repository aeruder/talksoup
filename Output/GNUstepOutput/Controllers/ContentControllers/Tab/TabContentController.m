/***************************************************************************
                        TabContentController.m
                          -------------------
    begin                : Fri Aug 27 11:56:47 CDT 2004
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

#import "Controllers/ContentControllers/Tab/TabContentController.h"
#import "Controllers/ContentControllers/Tab/TabMasterController.h"

@implementation TabContentController
+ (Class)masterClass
{
	return [TabMasterController class];
}
@end
