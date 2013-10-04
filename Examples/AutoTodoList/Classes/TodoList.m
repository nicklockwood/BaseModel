//
//  TodoList.m
//  TodoListExample
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "TodoList.h"
#import "TodoItem.h"


@implementation TodoList

- (void)setUp	{	TRACE_CALL(_cmd, self, nil);	_items = NSMutableArray.new;	}

- (void)setWithArray:(NSArray*)array	{	TRACE_CALL(_cmd, self, array, nil);

	[self.items setArray:[TodoItem instancesWithArray:array]]; 	//initialise with default list from plist

	printf("Just called +[TodoItem instancesWithArray:\n\t%s];\n"
			 "Note: initialise with default list from plist (%s)\nResource file:%s\nSave file:%s\n",
			 [[array valueForKey:@"description"] componentsJoinedByString:@"\n\t"].UTF8String,
			 NSStringFromSelector(_cmd).UTF8String, self.class.resourceFile.UTF8String, self.class.saveFile.UTF8String);
}

//- (BOOL) useHRCoderIfAvailable { return YES; } note: we don't implement NSCoding methods as the AutoCoding library takes care of this by default.

@end
