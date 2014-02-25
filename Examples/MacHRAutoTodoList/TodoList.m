
//  TodoList.m -  TodoListExample
//  Created by Alex Gray on 11/26/12. -	Part of BaseModel by Nick Lockwood.

#import "Todos.h"

@implementation TodoList

/*!	@note we've not implemented the NSCoding methods or setWithArray/Dictionary, etc
          because the HRCoder and AutoCoding libraries take care of this for us 	
*/
- (TodoItem*) newTodo
{
	TodoItem *newOne = TodoItem.instance;
	[self insertObject:newOne inItemsAtIndex:_items.count];  // KVO Array insertion trigger.
	return newOne;
}

- (TodoItem*) copyTodo:(TodoItem*)todo
{
	TodoItem *newOne = todo.copy;
	[self insertObject:newOne inItemsAtIndex:_items.count];
	return newOne;
}

/*! Subclass specific KVO Compliant "items" accessors to trigger NSArrayController updates on inserts / removals. */
{
    return self.items.count;
}

- (NSUInteger)                             countOfItems               { return self.items.count; }
{
    return self.items[index];
}

-         (id)                     objectInItemsAtIndex:(NSUInteger)i {	return self.items[i];	}
-       (void)             removeObjectFromItemsAtIndex:(NSUInteger)i {	[self.items removeObjectAtIndex:i];	}
{
    [self.items removeObjectAtIndex:index];
}

-       (void) insertObject:(TodoItem*)t inItemsAtIndex:(NSUInteger)i {	[self.items insertObject:t atIndex:i];	}
{
    [self.items insertObject:todo atIndex:index];
}

@end
