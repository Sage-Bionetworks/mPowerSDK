//
//  SBAMedicationTests.m
//  mPowerSDK
//
// Copyright (c) 2016, Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ResourcesTests.h"
@import mPowerSDK;
@import BridgeAppSDK;

@interface SBAMedicationTests : ResourcesTestCase

@end

@implementation SBAMedicationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUnarchive {
    
    NSString *dataRep =@"YnBsaXN0MDDUAQIDBAUGQ0RYJHZlcnNpb25YJG9iamVjdHNZJGFyY2hpdmVyVCR0b3ASAAGGoK8QFAcIDhIlJicoKSorLC40NTY3ODxAVSRudWxs0gkKCw1aTlMub2JqZWN0c1YkY2xhc3OhDIACgBPSDwoQEVpkaWN0aW9uYXJ5gAOAEtMTCQoUHCRXTlMua2V5c6cVFhcYGRobgASABYAGgAeACIAJgAqnHR4fIB0gI4ALgA2ADoAPgAuAD4AQgBFWZGV0YWlsWWZyZXF1ZW5jeVh0cmFja2luZ1ppZGVudGlmaWVyVWJyYW5kVG5hbWVZaW5qZWN0aW9u0QotgAzSLzAxMlokY2xhc3NuYW1lWCRjbGFzc2VzVk5TTnVsbKIxM1hOU09iamVjdBAECVhMZXZvZG9wYQjSLzA5OlxOU0RpY3Rpb25hcnmiOzNcTlNEaWN0aW9uYXJ50i8wPT5dQVBITWVkaWNhdGlvbqI/M11BUEhNZWRpY2F0aW9u0i8wQUJXTlNBcnJheaJBM18QD05TS2V5ZWRBcmNoaXZlctFFRlRyb290gAEACAARABoAIwAtADIANwBOAFQAWQBkAGsAbQBvAHEAdgCBAIMAhQCMAJQAnACeAKAAogCkAKYAqACqALIAtAC2ALgAugC8AL4AwADCAMkA0wDcAOcA7QDyAPwA/wEBAQYBEQEaASEBJAEtAS8BMAE5AToBPwFMAU8BXAFhAW8BcgGAAYUBjQGQAaIBpQGqAAAAAAAAAgEAAAAAAAAARwAAAAAAAAAAAAAAAAAAAaw=";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:dataRep options:0];
    
    SBAMedication *input = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"identifier"            : @"Levodopa",
                                                                                     @"name"                  : @"Levodopa",
                                                                                     @"tracking"              : @(true),
                                                                                     @"frequency"             : @(4)}];

    
    XCTAssertNotNil(data);
    if (data == nil) {
        return;
    }
    
    // Unarchive
    NSArray *unarchivedItems = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertTrue([unarchivedItems isKindOfClass:[NSArray class]]);
    if (![unarchivedItems isKindOfClass:[NSArray class]]) {
        return;
    }
    
    SBAMedication *med = unarchivedItems.firstObject;
    XCTAssertTrue([med isKindOfClass:[SBAMedication class]]);
    if (![med isKindOfClass:[SBAMedication class]]) {
        return;
    }
    
    XCTAssertEqualObjects(input, med);
    XCTAssertEqualObjects(input.identifier, med.identifier);
    XCTAssertEqualObjects(input.name, med.name);
    XCTAssertEqualObjects(input.brand, med.brand);
    XCTAssertEqual(input.frequency, med.frequency);
}

@end
