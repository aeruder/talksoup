#import "HistoryCommands.h"


@implementation HistoryCommands
-(id)init
{
    if([super init] != nil)
	    history=[[NSMutableDictionary alloc] init];

    return self;
};

-(void)dealloc
{
	if (history!=nil) 
		[history release]; 

	[super dealloc];

};

-(void)addNewChannel:(NSString *)channelName
{
    if(channelName)
	    [history setObject:[NSMutableArray array] forKey:channelName];
	
}

-(void)removeChannel:(NSString *)channelName
{
    if(channelName)
	    [history removeObjectForKey:channelName];
}

	
- (void)appendCommand:(NSString *)aLine 
	        toChannel:(NSString *)channelName
{
    if(!aLine || !channelName)
        return;
        
	NSMutableArray *commands = [history objectForKey:channelName];

	[commands insertObject:aLine atIndex:0];
		
};

- (id)getCommand:(int)index
     fromChannel:(NSString *)channelName
{
    if(!channelName) return nil;
    
	NSMutableArray *commands = [history objectForKey:channelName];

	return [commands objectAtIndex:index];
	
};
@end

