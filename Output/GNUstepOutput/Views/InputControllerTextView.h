/***************************************************************************
                       InputControllerTextView.h
                          -------------------
    begin                : Wed Jul 13 01:02:02 CDT 2005
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

@class InputControllerTextView;

#import "Views/FocusNotificationTextView.h"

@class NSString;

/**
 * This is used as the main input text view.  It does not allow
 * returns or enters to make it into the textview at all (except
 * possibly programmatically).  It will trigger an event for each
 * return while properly inserting the correct amount of text.
 */
@interface InputControllerTextView : FocusNotificationTextView
	{
	}
- (void)insertText: (NSString *)someText;
@end
