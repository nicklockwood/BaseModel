//
//  TodoItem.m
//  TodoList
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "TodoItem.h"
#import "TodoList.h"

@implementation TodoItem

+ (instancetype) instanceWithLabel:(NSString*)label	{	TRACE_CALL(_cmd, self, label, nil);

	return [self instanceWithObject:label];
}
- 			 (void) setWithString:	  (NSString*)string	{	TRACE_CALL(_cmd, self, string, nil);

	_label = string;
}
- 			 (void) save											{	TRACE_CALL(_cmd, self, nil);

	[TodoList.sharedInstance save]; 	/*save the todolist*/
}

//- (BOOL) useHRCoderIfAvailable { return YES; } note: we don't implement NSCoding methods as the AutoCoding library takes care of this by default.

@end
