/***************************************************************************
                                GroupEditorController.m
                          -------------------
    begin                : Tue May  6 14:34:46 CDT 2003
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

#import "Controllers/GroupEditorController.h"

#import <Foundation/NSString.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>

@implementation GroupEditorController
- (void)awakeFromNib
{
	[window makeKeyAndOrderFront: nil];
	[window makeFirstResponder: entryField];
}
- (void)dealloc
{
	[entryField setDelegate: nil];
	DESTROY(window);
	
	[super dealloc];
}
- (NSButton *)okButton
{
	return okButton;
}
- (NSTextField *)extraField
{
	return extraField;
}
- (NSTextField *)entryField
{
	return entryField;
}
- (NSWindow *)window
{
	return window;
}
- (void)setEntry: (NSTextField *)sender
{
	[okButton performClick: nil];
}
@end
 
