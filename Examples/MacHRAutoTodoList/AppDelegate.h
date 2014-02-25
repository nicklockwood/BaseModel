
//  AppDelegate.h -  MacHRAutoTodoList
//  Created by Alex Gray on 11/26/12.   Copyright (c) 2012 Alex Gray. All rights reserved.

#import "Todos.h"

@interface                AppDelegate : NSObject

@property (weak) IBOutlet	NSTableView * table;
@property (readonly)		     TodoList * todos;

- (IBAction) newTodo:       (id)x;
- (IBAction) loadFromPlist:	(id)x;
- (IBAction) copyTodo:      (id)x;
- (IBAction) saveTodos:     (id)x;
- (IBAction) deleteAll:     (id)x;

@end

