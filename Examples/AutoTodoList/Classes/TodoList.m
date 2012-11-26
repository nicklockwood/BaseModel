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

@synthesize items;

- (void)setUp
{
    self.items = [NSMutableArray array];
}

- (void)setWithArray:(NSArray *)array
{
	//initialise with default list from plist
	[items setArray:[TodoItem instancesWithArray:array]];
}

//note: we've not implemented the NSCoding methods
//the AutoCoding library takes care of this for us


@end
