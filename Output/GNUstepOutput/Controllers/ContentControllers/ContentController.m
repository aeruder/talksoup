/***************************************************************************
                                ContentController.m
                          -------------------
    begin                : Mon Jan 19 12:09:57 CST 2004
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

#import "Controllers/ContentControllers/ContentController.h"
#import <Foundation/NSString.h>

NSString *ContentControllerChannelType = @"ContentControllerChannelType";
NSString *ContentControllerQueryType = @"ContentControllerQueryType";

NSString *ContentConsoleName = @"ContentConsoleName";

NSString *ContentControllerMovedInMasterControllerNotification = @"ContentControllerMovedInMasterControllerNotification";
NSString *ContentControllerAddedToMasterControllerNotification = @"ContentControllerAddedToMasterControllerNotification";
NSString *ContentControllerRemovedFromMasterControllerNotification = @"ContentControllerRemovedFromMasterControllerNotification";
NSString *ContentControllerChangedNicknameNotification = @"ContentControllerChangedNicknameNotification";
NSString *ContentControllerChangedTitleNotification = @"ContentControllerChangedTitleNotification";
NSString *ContentControllerSelectedNameNotification = @"ContentControllerSelectedNameNotification";
NSString *ContentControllerChangedLabelNotification = @"ContentControllerChangedLabelNotification";

