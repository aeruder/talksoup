/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef Label_h
#define Label_h

#include <AppKit/NSTextField.h>

@interface NSTextField (label)
+ newLabel: (NSString *)title;
@end

#endif

