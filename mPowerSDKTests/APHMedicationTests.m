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

- (void)testCreateFromResourceFile {
    
    NSArray <SBAMedication *> *meds = [self resourceMedicationTracking];
    
    NSUInteger expectedCount = 15;
    XCTAssertEqual(meds.count, expectedCount);
    if (meds.count != expectedCount) {
        return;
    }
    
    SBAMedication *levodopa = meds[0];
    XCTAssertEqualObjects(levodopa.identifier, @"Levodopa");
    XCTAssertEqualObjects(levodopa.name, @"Levodopa");
    XCTAssertEqualObjects(levodopa.text, @"Levodopa");
    XCTAssertEqualObjects(levodopa.shortText, @"Levodopa");
    XCTAssertTrue(levodopa.tracking);
    XCTAssertFalse(levodopa.injection);
    
    SBAMedication *carbidopa = meds[1];
    XCTAssertEqualObjects(carbidopa.identifier, @"Carbidopa");
    XCTAssertEqualObjects(carbidopa.name, @"Carbidopa");
    XCTAssertEqualObjects(carbidopa.text, @"Carbidopa");
    XCTAssertEqualObjects(carbidopa.shortText, @"Carbidopa");
    XCTAssertFalse(carbidopa.tracking);
    XCTAssertFalse(carbidopa.injection);
    
    SBAMedication *rytary = meds[2];
    XCTAssertEqualObjects(rytary.identifier, @"Rytary");
    XCTAssertEqualObjects(rytary.name, @"Carbidopa/Levodopa");
    XCTAssertEqualObjects(rytary.brand, @"Rytary");
    XCTAssertEqualObjects(rytary.text, @"Carbidopa/Levodopa (Rytary)");
    XCTAssertEqualObjects(rytary.shortText, @"Rytary");
    XCTAssertTrue(rytary.tracking);
    XCTAssertFalse(rytary.injection);
    
    SBAMedication *duopa = [meds lastObject];
    XCTAssertEqualObjects(duopa.identifier, @"Duopa");
    XCTAssertEqualObjects(duopa.name, @"Carbidopa/Levodopa");
    XCTAssertEqualObjects(duopa.brand, @"Duopa");
    XCTAssertEqualObjects(duopa.detail, @"Continuous Infusion");
    XCTAssertEqualObjects(duopa.text, @"Carbidopa/Levodopa Continuous Infusion (Duopa)");
    XCTAssertEqualObjects(duopa.shortText, @"Duopa");
    XCTAssertFalse(duopa.tracking);
    XCTAssertTrue(duopa.injection);
    
}

- (void)testArchiveAndUnarchive {
    
    NSArray <SBAMedication *> *meds = [self resourceMedicationTracking];
    
    // Check assumptions
    SBAMedication *levodopa = meds.firstObject;
    XCTAssertNotNil(levodopa);
    if (!levodopa) {
        return;
    }
    
    // Modify the frequency
    levodopa.frequency = 4;
    
    NSDictionary *dictionary = [levodopa dictionaryRepresentation];
    
    // Archive
    NSArray *selecedItems = @[levodopa];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:selecedItems];
    
    [self unarchiveData:data input:levodopa];
}

- (void)testUnarchive {
    
    NSString *dataRep =@"YnBsaXN0MDDUAQIDBAUGQ0RYJHZlcnNpb25YJG9iamVjdHNZJGFyY2hpdmVyVCR0b3ASAAGGoK8QFAcIDhIlJicoKSorLC40NTY3ODxAVSRudWxs0gkKCw1aTlMub2JqZWN0c1YkY2xhc3OhDIACgBPSDwoQEVpkaWN0aW9uYXJ5gAOAEtMTCQoUHCRXTlMua2V5c6cVFhcYGRobgASABYAGgAeACIAJgAqnHR4fIB0gI4ALgA2ADoAPgAuAD4AQgBFWZGV0YWlsWWZyZXF1ZW5jeVh0cmFja2luZ1ppZGVudGlmaWVyVWJyYW5kVG5hbWVZaW5qZWN0aW9u0QotgAzSLzAxMlokY2xhc3NuYW1lWCRjbGFzc2VzVk5TTnVsbKIxM1hOU09iamVjdBAECVhMZXZvZG9wYQjSLzA5OlxOU0RpY3Rpb25hcnmiOzNcTlNEaWN0aW9uYXJ50i8wPT5dQVBITWVkaWNhdGlvbqI/M11BUEhNZWRpY2F0aW9u0i8wQUJXTlNBcnJheaJBM18QD05TS2V5ZWRBcmNoaXZlctFFRlRyb290gAEACAARABoAIwAtADIANwBOAFQAWQBkAGsAbQBvAHEAdgCBAIMAhQCMAJQAnACeAKAAogCkAKYAqACqALIAtAC2ALgAugC8AL4AwADCAMkA0wDcAOcA7QDyAPwA/wEBAQYBEQEaASEBJAEtAS8BMAE5AToBPwFMAU8BXAFhAW8BcgGAAYUBjQGQAaIBpQGqAAAAAAAAAgEAAAAAAAAARwAAAAAAAAAAAAAAAAAAAaw=";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:dataRep options:0];
    
    SBAMedication *input = [[SBAMedication alloc] initWithDictionaryRepresentation:@{@"identifier"            : @"Levodopa",
                                                                                     @"name"                  : @"Levodopa",
                                                                                     @"tracking"              : @(true),
                                                                                     @"frequency"             : @(4)}];
    [self unarchiveData:data input:input];
    
}

- (void)unarchiveData:(NSData*)data input:(SBAMedication*)input {
    
    XCTAssertNotNil(data);
    if (data == nil) {
        return;
    }
    
    // Unarchive
    NSArray *unarchivedItems = [APHMedicationTrackerKeyedUnarchiver unarchiveObjectWithData:data];
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

- (NSArray <SBAMedication *> *)resourceMedicationTracking {
    
    // Pull the medication from the resource bundle
    NSDictionary *json = [self jsonForResource:@"MedicationTracking"];
    XCTAssertTrue([json isKindOfClass:[NSDictionary class]]);
    
    if (![json isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSArray *items = json[@"items"];
    XCTAssertTrue([items isKindOfClass:[NSArray class]]);
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSMutableArray *medItems = [NSMutableArray new];
    for (NSDictionary *item in items) {
        XCTAssertTrue([item isKindOfClass:[NSDictionary class]]);
        if (![item isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        
        SBAMedication *med = [[SBAMedication alloc] initWithDictionaryRepresentation:item];
        [medItems addObject:med];
    }
    
    return [medItems copy];
}



@end
