//
//  ResourcesTests.m
//  mPowerSDK
//
//  Created by Shannon Young on 1/12/16.
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <APCAppCore/APCAppCore.h>
#import <mPowerSDK/mPowerSDK.h>

@interface ResourcesTests : XCTestCase

@end

@implementation ResourcesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDataGroupsMapping
{
    id json = [self jsonForResource:@"DataGroupsMapping"];
    XCTAssertTrue([json isKindOfClass:[NSDictionary class]]);
}

- (id)jsonForResource:(NSString*)resourceName
{
    APHAppDelegate *appDelegate = [[APHAppDelegate alloc] init];
    NSString *path = [appDelegate pathForResource:resourceName ofType:@"json"];
    
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(jsonData);
    
    if (jsonData) {
        NSError *parseError;
        id json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&parseError];
        XCTAssertNil(parseError);
        XCTAssertNotNil(json);
        
        return json;
    }
    
    return nil;
}

@end
