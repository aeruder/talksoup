#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "IRCApp.h"

int
main (int argc, const char *argv[])
{
  CREATE_AUTORELEASE_POOL (arp);
  [NSApplication sharedApplication];

  [NSApp setDelegate:[[IRCApp alloc] init]];
  [NSApp run];

  DESTROY (arp);

  return 0;
};
