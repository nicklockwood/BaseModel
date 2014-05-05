//
//  Tests.m
//
//  Created by Nick Lockwood on 12/01/2012.
//  Copyright (c) 2012 Charcoal Design. All rights reserved.
//

#import "Tests.h"
#import "BaseModel.h"


@interface TestModel : BaseModel

@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSDate *date;

@end


@implementation TestModel

+ (BMFileFormat)saveFormat
{
    return BMFileFormatJSON;
}

@end


@implementation Tests

- (void)testSetSharedInstanceToNil
{
    //set property on shared instance
    [TestModel sharedInstance].string = @"foo";
    
    //replace shared instance
    [TestModel setSharedInstance:nil];
    
    //verify that it worked
    NSAssert([TestModel sharedInstance].string == nil, @"Failed to clear shared instance");
}

- (void)testSaveDateAsJSON
{
    [TestModel sharedInstance].date = [NSDate date];
    [[TestModel sharedInstance] save];
}

@end
