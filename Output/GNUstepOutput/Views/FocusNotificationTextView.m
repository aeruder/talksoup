/***************************************************************************
                         FocusNotificationTextView.m
                          -------------------
    begin                : Mon Jun 27 23:53:30 CDT 2005
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

#import "Views/FocusNotificationTextView.h"

@implementation FocusNotificationTextView
- (BOOL)resignFirstResponder
{
	id delegate;
	if (![super resignFirstResponder]) return NO;

	delegate = [self delegate];
	if (delegate && [delegate respondsToSelector: @selector(textViewResignedFocus:)])
	{
		[delegate textViewResignedFocus: self];
	}

	return YES;
}
- (BOOL)becomeFirstResponder
{
	id delegate;

	if (![super becomeFirstResponder]) return NO;

	delegate = [self delegate];
	if (delegate && [delegate respondsToSelector: @selector(textViewTookFocus:)])
	{
		[delegate textViewTookFocus: self];
	}

	return YES;
}
@end
