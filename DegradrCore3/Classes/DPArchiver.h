//
//  DPArchiver.h
//  DegradrCore3
//
//  Created by denis svinarchuk on 19.08.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DPCoding <NSObject>

- (NSDictionary*) toDictionary;
- (void) fromDictionary:(NSDictionary*)dictionary;

@end

@interface DPArchiver : NSObject
+ (NSString*)     jsonFromCoding:(id<DPCoding>)endocder;
+ (NSDictionary*) dictionaryFromJson:(NSString*)json;
@end