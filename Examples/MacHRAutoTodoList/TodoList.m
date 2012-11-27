//
//  TodoList.m
//  TodoListExample
//
//  Created by Nick Lockwood on 28/07/2011.
//  Copyright 2011 Charcoal Design. All rights reserved.
//

#import "Todos.h"

@implementation TodoList

@synthesize items;

/*	note: we've not implemented the NSCoding methods or setWithArray/Dictionary, etc
	because the HRCoder and AutoCoding libraries take care of this for us 	*/

- (TodoItem*) newTodo
{
	TodoItem *newOne = [TodoItem instance];
	[self insertObject:newOne inItemsAtIndex:self.items.count];
	return newOne;
}
- (TodoItem*) copyTodo:(TodoItem*)todo;
{
	TodoItem *newOne = todo.copy;
	[self insertObject:newOne inItemsAtIndex:items.count];
	return newOne;
}

- (NSUInteger)countOfItems { 					return self.items.count; }

- (id)objectInItemsAtIndex:(NSUInteger)index {	return self.items[index];	 }

- (void)removeObjectFromItemsAtIndex:(NSUInteger)index {				 	[self.items removeObjectAtIndex:index];	}

- (void)insertObject:(TodoItem*)todo inItemsAtIndex:(NSUInteger)index {	[self.items insertObject:todo atIndex:index];	}

@end
