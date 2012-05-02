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

//override the generic sharedInstance
//with a concrete type, this makes it
//easier to use without casting
+ (TodoList *)sharedInstance
{
	return [super sharedInstance];
}

- (void)setUp
{
    self.items = [NSMutableArray array];
}

- (void)setWithCoder:(NSCoder *)aDecoder
{
	//replace default list with version from saved file
	[items setArray:[aDecoder decodeObjectForKey:@"items"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:items forKey:@"items"];
}

- (void)dealloc
{
	[items release];
	[super dealloc];
}

@end
