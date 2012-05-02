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

- (void)setWithCoder:(NSCoder *)aDecoder
{
	self.label = [aDecoder decodeObjectForKey:@"label"];
	self.checked = [aDecoder decodeBoolForKey:@"checked"];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:label forKey:@"label"];
	[aCoder encodeBool:checked forKey:@"checked"];
}

- (void)save
{
	//save the todolist
	[[TodoList sharedInstance] save];
}

- (void)dealloc
{
	[label release];
	[super dealloc];
}


@end
