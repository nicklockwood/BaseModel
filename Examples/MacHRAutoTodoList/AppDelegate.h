//
//  AppDelegate.h
//  MacHRAutoTodoList
//
//  Created by Alex Gray on 11/26/12.
//  Copyright (c) 2012 Alex Gray. All rights reserved.
//


#import "Todos.h"

@interface TodoColorCell : NSActionCell
@end
@interface TodoPriorityClickCell : NSActionCell
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet	NSTableView *table;
@property (nonatomic)		TodoList 	*todos;

- (IBAction) newTodo:		(id)sender;
- (IBAction) loadFromPlist:	(id)sender;
- (IBAction) copyTodo:		(id)sender;
- (IBAction) saveTodos:		(id)sender;
- (IBAction) deleteAll:		(id)sender;

@end

