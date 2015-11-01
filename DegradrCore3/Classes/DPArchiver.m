//
//  DPArchiver.m
//  DegradrCore3
//
//  Created by denis svinarchuk on 19.08.15.
//  Copyright (c) 2015 Degradr.Photo. All rights reserved.
//

#import "DPArchiver.h"

@interface DPArchiver()
@end

@implementation DPArchiver

+ (NSString*) jsonFromCoding:(id<DPCoding>)endocder{
    NSError  *error;
    NSDictionary *dict = [endocder toDictionary];
    NSData   *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (error) {
        NSLog(@" *** DPArchiver error: %@", error);
    }
    return json;
}

+ (NSDictionary*) dictionaryFromJson:(NSString *)jsonString{
    return [NSJSONSerialization JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves|NSJSONReadingAllowFragments error:nil];
}

@end