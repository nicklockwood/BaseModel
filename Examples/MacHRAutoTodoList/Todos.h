
//  TodoItem.h
//  TodoList

//  Created by Alex Gray on 11/26/12.
//	Part of BaseModel by Nick Lockwood.

#import "BaseModel.h"

@interface TodoItem : BaseModel

@property (readonly) 		  NSColor  	*color;
@property (nonatomic, strong) NSString  *label;
@property (nonatomic, strong) NSNumber  *priority;
@property (nonatomic) 		  BOOL       checked;

@end

@interface TodoList : BaseModel

@property (nonatomic, strong) NSMutableArray *items;

- (TodoItem*) newTodo;
- (TodoItem*) copyTodo: (TodoItem*)todo;

// Subclass specific KVO Compliant "items" accessors to trigger NSArrayController updates on inserts / removals.
- (NSUInteger)	 countOfItems;
- (id)	 objectInItemsAtIndex:		   (NSUInteger) index;
- (void) removeObjectFromItemsAtIndex: (NSUInteger) index;
- (void)         insertObject:		   (TodoItem*)  todo
			   inItemsAtIndex:		   (NSUInteger) index;

@end
