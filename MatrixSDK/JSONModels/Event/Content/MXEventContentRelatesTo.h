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

#import <Foundation/Foundation.h>

#import "MXJSONModel.h"
#import "MXInReplyTo.h"

NS_ASSUME_NONNULL_BEGIN

/**
 JSON model for MXEvent.content.relates_to.
 */
@interface MXEventContentRelatesTo : MXJSONModel

@property (nonatomic, readonly, nullable) NSString *relationType;     // Ex: MXEventRelationTypeAnnotation
@property (nonatomic, readonly, nullable) NSString *eventId;
@property (nonatomic, readonly, nullable) NSString *key;
@property (nonatomic, readonly, nullable) MXInReplyTo *inReplyTo;

- (instancetype)initWithRelationType:(NSString *)relationType
                             eventId:(NSString *)eventId;

- (instancetype)initWithRelationType:(NSString *)relationType
                             eventId:(NSString *)eventId
                                 key:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
