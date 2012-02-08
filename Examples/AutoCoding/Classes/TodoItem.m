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

@synthesize label;
@synthesize checked;

+ (TodoItem *)instanceWithLabel:(NSString *)_label
{
	TodoItem *item = [self instance];
	item.label = _label;
	return item;
}

- (void)save
{
	//save the todolist
	[[TodoList sharedInstance] save];
}

//note: we've not implemented the NSCoding methods
//the AutoCoding library takes care of this for us

- (void)dealloc
{
	[label release];
	[super dealloc];
}


@end
