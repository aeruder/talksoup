#include <Foundation/NSRunLoop.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSMenu.h>


@class IRCWindowController;
@class ServersManager;
@class PreferencesWindowController;

@interface IRCApp : NSObject
{
    PreferencesWindowController *pwc;
}
+(void)connectToServer:(NSString *)server
                onPort:(int)port
           withTimeout:(int)timeout
         withNicknames:(NSArray *)nicks;

- (id)init;
- (void)dealloc;
@end
