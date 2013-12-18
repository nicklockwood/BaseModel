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

- (void)setUp
{
    self.items = [NSMutableArray array];
}

- (void)setWithArray:(NSArray *)array
{
	//initialise with default list from plist
	[self.items setArray:[TodoItem instancesWithArray:array]];
}

//NOTE: no need to implement the NSCoding methods
//BaseModel does that for us automagically

@end
