#include <Foundation/NSString.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSUserDefaults.h>


@interface HistoryCommands : NSObject
{
	NSMutableDictionary *history;	
};
-(id)init;
-(void)dealloc;
-(void)addNewChannel:(NSString *)channelName;
-(void)removeChannel:(NSString *)channelName;
-(void)appendCommand:(NSString *)aLine
           toChannel:(NSString *)channelName;
- (id)getCommand:(int)index
     fromChannel:(NSString *)channelName;
@end
