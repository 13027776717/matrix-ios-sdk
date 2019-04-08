/*
 Copyright 2019 New Vector Ltd

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

#import "MXSASTransaction.h"
#import "MXSASTransaction_Private.h"

#import "MXDeviceVerificationManager_Private.h"

#pragma mark - Constants

NSString * const kMXKeyVerificationMethodSAS        = @"m.sas.v1";
NSString * const kMXKeyVerificationSASModeDecimal   = @"decimal";
NSString * const kMXKeyVerificationSASModeEmoji     = @"emoji";

NSArray<NSString*> *kKnownAgreementProtocols;
NSArray<NSString*> *kKnownHashes;
NSArray<NSString*> *kKnownMacs;
NSArray<NSString*> *kKnownShortCodes;

static NSArray<MXEmojiRepresentation*> *kSasEmojis;


@implementation MXSASTransaction

- (NSString *)sasDecimal
{
    NSString *sasDecimal;
    if (_sasBytes)
    {
        sasDecimal = [[MXSASTransaction decimalRepresentationForSas:_sasBytes] componentsJoinedByString:@" "];
    }

    return sasDecimal;
}

- (NSArray<MXEmojiRepresentation *> *)sasEmoji
{
    NSArray *sasEmoji;
    if (_sasBytes)
    {
        sasEmoji = [MXSASTransaction emojiRepresentationForSas:_sasBytes];
    }

    return sasEmoji;
}


#pragma mark - SDK-Private methods -

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        kKnownAgreementProtocols = @[@"curve25519"];
        kKnownHashes = @[@"sha256"];
        kKnownMacs = @[@"hmac-sha256"];
        kKnownShortCodes = @[kMXKeyVerificationSASModeEmoji, kMXKeyVerificationSASModeDecimal];

        [self initializeSasEmojis];
    });
}

- (instancetype)initWithOtherUser:(NSString *)otherUser andOtherDevice:(NSString *)otherDevice manager:(MXDeviceVerificationManager *)manager
{
    self = [super initWithOtherUser:otherUser andOtherDevice:otherDevice manager:manager];
    if (self)
    {
        _olmSAS = [OLMSAS new];
    }
    return self;
}

- (NSString*)hashUsingAgreedHashMethod:(NSString*)string
{
    NSString *hashUsingAgreedHashMethod;
    if ([_accepted.hashAlgorithm isEqualToString:@"sha256"])
    {
        hashUsingAgreedHashMethod = [[OLMUtility new] sha256:[string dataUsingEncoding:NSUTF8StringEncoding]];
    }

    return hashUsingAgreedHashMethod;
}


#pragma mark -Private methods -

#pragma mark - Decimal representation
+ (NSArray<NSNumber*> *)decimalRepresentationForSas:(NSData*)sas
{
    UInt8 *sasBytes = (UInt8 *)sas.bytes;

    /**
     *      +--------+--------+--------+--------+--------+
     *      | Byte 0 | Byte 1 | Byte 2 | Byte 3 | Byte 4 |
     *      +--------+--------+--------+--------+--------+
     * bits: 87654321 87654321 87654321 87654321 87654321
     *       \____________/\_____________/\____________/
     *         1st number    2nd number     3rd number
     */
    return @[
             @((sasBytes[0] << 5 | sasBytes[1] >> 3) + 1000),
             @(((sasBytes[1] & 0x7) << 10 | sasBytes[2] << 2 | sasBytes[3] >> 6) + 1000),
             @(((sasBytes[3] & 0x3f) << 7 | sasBytes[4] >> 1) + 1000),
             ];
}


#pragma mark - Emoji representation
+ (void)initializeSasEmojis
{
    kSasEmojis = @[
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐶" andName:@"dog"],        //  0
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐱" andName:@"cat"],        //  1
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🦁" andName:@"lion"],       //  2
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐎" andName:@"horse"],      //  3
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🦄" andName:@"unicorn"],    //  4
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐷" andName:@"pig"],        //  5
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐘" andName:@"elephant"],   //  6
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐰" andName:@"rabbit"],     //  7
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐼" andName:@"panda"],      //  8
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐓" andName:@"rooster"],    //  9
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐧" andName:@"penguin"],    // 10
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐢" andName:@"turtle"],     // 11
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐟" andName:@"fish"],       // 12
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🐙" andName:@"octopus"],    // 13
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🦋" andName:@"butterfly"],  // 14
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🌷" andName:@"flower"],     // 15
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🌳" andName:@"tree"],       // 16
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🌵" andName:@"cactus"],     // 17
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🍄" andName:@"mushroom"],   // 18
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🌏" andName:@"globe"],      // 19
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🌙" andName:@"moon"],       // 20
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"☁️" andName:@"cloud"],      // 21
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🔥" andName:@"fire"],       // 22
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🍌" andName:@"banana"],     // 23
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🍎" andName:@"apple"],      // 24
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🍓" andName:@"strawberry"], // 25
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🌽" andName:@"corn"],       // 26
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🍕" andName:@"pizza"],      // 27
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎂" andName:@"cake"],       // 28
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"❤️" andName:@"heart"],      // 29
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🙂" andName:@"smiley"],     // 30
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🤖" andName:@"robot"],      // 31
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎩" andName:@"hat"],        // 32
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"👓" andName:@"glasses"],    // 33
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🔧" andName:@"spanner"],    // 34
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎅" andName:@"santa"],      // 35
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"👍" andName:@"thumbs up"],  // 36
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"☂️" andName:@"umbrella"],   // 37
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"⌛" andName:@"hourglass"],  // 38
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"⏰" andName:@"clock"],      // 39
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎁" andName:@"gift"],       // 40
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"💡" andName:@"light bulb"], // 41
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"📕" andName:@"book"],       // 42
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"✏️" andName:@"pencil"],     // 43
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"📎" andName:@"paperclip"],  // 44
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"✂️" andName:@"scissors"],   // 45
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🔒" andName:@"padlock"],    // 46
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🔑" andName:@"key"],        // 47
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🔨" andName:@"hammer"],     // 48
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"☎️" andName:@"telephone"],  // 49
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🏁" andName:@"flag"],       // 50
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🚂" andName:@"train"],      // 51
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🚲" andName:@"bicycle"],    // 52
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"✈️" andName:@"aeroplane"],  // 53
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🚀" andName:@"rocket"],     // 54
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🏆" andName:@"trophy"],     // 55
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"⚽" andName:@"ball"],       // 56
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎸" andName:@"guitar"],     // 57
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎺" andName:@"trumpet"],    // 58
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🔔" andName:@"bell"],       // 59
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"⚓️" andName:@"anchor"],     // 60
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"🎧" andName:@"headphones"], // 61
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"📁" andName:@"folder"],     // 62
                   [[MXEmojiRepresentation alloc] initWithEmoji:@"📌" andName:@"pin"],        // 63
                   ];
}

+ (NSArray<MXEmojiRepresentation*> *)emojiRepresentationForSas:(NSData*)sas
{
    UInt8 *sasBytes = (UInt8 *)sas.bytes;

    return @[
             kSasEmojis[sasBytes[0] >> 2],
             kSasEmojis[(sasBytes[0] & 0x3) << 4 | sasBytes[1] >> 4],
             kSasEmojis[(sasBytes[1] & 0xf) << 2 | sasBytes[2] >> 6],
             kSasEmojis[sasBytes[2] & 0x3f],
             kSasEmojis[sasBytes[3] >> 2],
             kSasEmojis[(sasBytes[3] & 0x3) << 4 | sasBytes[4] >> 4],
             kSasEmojis[(sasBytes[4] & 0xf) << 2 | sasBytes[5] >> 6]
             ];
}

@end
