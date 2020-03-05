/*
 Copyright 2020 The Matrix.org Foundation C.I.C
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import <XCTest/XCTest.h>

#import "MXCrypto_Private.h"
#import "MXCryptoStore.h"
#import "MXSession.h"

#import "MatrixSDKTestsData.h"
#import "MatrixSDKTestsE2EData.h"


@interface MXCryptoSecretShareTests : XCTestCase
{
    MatrixSDKTestsData *matrixSDKTestsData;
    MatrixSDKTestsE2EData *matrixSDKTestsE2EData;
}

@end


@implementation MXCryptoSecretShareTests

- (void)setUp
{
    [super setUp];
    
    matrixSDKTestsData = [[MatrixSDKTestsData alloc] init];
    matrixSDKTestsE2EData = [[MatrixSDKTestsE2EData alloc] initWithMatrixSDKTestsData:matrixSDKTestsData];
}

- (void)tearDown
{
    matrixSDKTestsData = nil;
    matrixSDKTestsE2EData = nil;
}

/**
 Tests secrets storage in MXCryptoStore.
 */
- (void)testLocalSecretStorage
{
    [matrixSDKTestsE2EData doE2ETestWithAliceInARoom:self readyToTest:^(MXSession *aliceSession, NSString *roomId, XCTestExpectation *expectation) {
        NSString *secretId = @"secretId";
        NSString *secret = @"A secret";
        NSString *secret2 = @"A secret2";

        XCTAssertNil([aliceSession.crypto.store secretWithSecretId:secretId]);
        
        [aliceSession.crypto.store storeSecret:secret withSecretId:secretId];
        XCTAssertEqualObjects([aliceSession.crypto.store secretWithSecretId:secretId], secret);
        
        [aliceSession.crypto.store storeSecret:secret2 withSecretId:secretId];
        XCTAssertEqualObjects([aliceSession.crypto.store secretWithSecretId:secretId], secret2);
        
        [aliceSession.crypto.store deleteSecretWithSecretId:secretId];
        XCTAssertNil([aliceSession.crypto.store secretWithSecretId:secretId]);
        
        [expectation fulfill];
    }];
}

/**
 Nomical case: Gossip a secret between 2 devices.
 
 - Alice has a secret on her 1st device
 - Alice logs in on a new device
 - Alice trusts the new device
 - Alice requests the secret from the new device
 -> She gets the secret
 */
- (void)testSecretShare
{
    [matrixSDKTestsE2EData doE2ETestWithAliceInARoom:self readyToTest:^(MXSession *aliceSession, NSString *roomId, XCTestExpectation *expectation) {
        
        NSString *secretId = @"secretId";
        NSString *secret = @"A secret";

        // - Alice has a secret on her 1st device
        [aliceSession.crypto.store storeSecret:secret withSecretId:secretId];
        
        // - Alice logs in on a new device
        [matrixSDKTestsE2EData loginUserOnANewDevice:aliceSession.matrixRestClient.credentials withPassword:MXTESTS_ALICE_PWD onComplete:^(MXSession *newAliceSession) {
            
            MXCredentials *newAlice = newAliceSession.matrixRestClient.credentials;
            
            // - Alice trusts the new device
            [aliceSession.crypto setDeviceVerification:MXDeviceVerified forDevice:newAlice.deviceId ofUser:newAlice.userId success:nil failure:nil];
            
            // - Alice requests the secret from the new device
            [newAliceSession.crypto.secretShareManager requestSecret:secretId toDeviceIds:nil success:^(NSString * _Nonnull requestId) {
                XCTAssertNotNil(requestId);
            } onSecretReceived:^(NSString * _Nonnull sharedSecret) {
                
                // -> She gets the secret
                XCTAssertEqualObjects(sharedSecret, secret);
                [expectation fulfill];
                
            } failure:^(NSError * _Nonnull error) {
                XCTFail(@"The operation should not fail - NSError: %@", error);
                [expectation fulfill];
            }];
        }];
    }];
}

@end
