//
//  BaseModelTests.m
//
//  Created by Nick Lockwood on 12/01/2012.
//  Copyright (c) 2012 Charcoal Design. All rights reserved.
//


#import <XCTest/XCTest.h>
#import "BaseModel.h"


@interface TestModel : BaseModel

@property (nonatomic, strong) NSString *string;
@property (nonatomic, strong) NSDate *date;

@end


@implementation TestModel

@synthesize string, date;

+ (BMFileFormat)saveFormat
{
    return BMFileFormatJSON;
}

@end


@interface BaseModelTests : XCTestCase

@end


@implementation BaseModelTests

- (void)testSetSharedInstanceToNil
{
    
    //set property on shared instance
    [TestModel sharedInstance].string = @"foo";
    
    //replace shared instance
    [TestModel setSharedInstance:nil];
    
    //verify that it worked
    XCTAssertFalse([TestModel hasSharedInstance]);
    XCTAssertNil([TestModel sharedInstance].string);
}

- (void)testSaveDateAsJSON
{
    [TestModel sharedInstance].date = [NSDate date];
    XCTAssertNoThrow([[TestModel sharedInstance] save]);
}

@end

