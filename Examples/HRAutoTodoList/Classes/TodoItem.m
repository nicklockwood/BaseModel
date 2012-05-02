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

+ (TodoItem *)instanceWithLabel:(NSString *)label
{
	TodoItem *instance = [self instance];
    instance.label = label;
    return instance;
}

- (void)save
{
	//save the todolist
	[[TodoList sharedInstance] save];
}

//note: we've not implemented the NSCoding methods
//or initWithString/Dictionary, etc because the HRCoder
//and AutoCoding libraries take care of this for us

- (void)dealloc
{
	[label release];
	[super dealloc];
}

@end
