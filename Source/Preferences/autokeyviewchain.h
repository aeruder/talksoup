/*
copyright 2002 Alexander Malmberg <alexander@malmberg.org>
*/

#ifndef autokeyviewchain_h
#define autokeyviewchain_h

@interface NSWindow (autokeyviewchain)
-(void) autoSetupKeyViewChain;
@end

@interface NSView (autokeyviewchain)
-(NSView *) autoSetupKeyViewChain: (NSView *) next;
@end

#endif

