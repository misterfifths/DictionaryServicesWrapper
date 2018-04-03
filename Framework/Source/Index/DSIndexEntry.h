// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSMutableDictionaryWrapper.h"
#import "DSCommon.h"


NS_ASSUME_NONNULL_BEGIN


@interface DSIndexEntry : DSMutableDictionaryWrapper<DSIndexFieldName, id>

@property (nonatomic) uint64_t externalBodyID;

@property (nonatomic) uint64_t privateFlag;
@property (nonatomic, getter=isCensored) BOOL censored;
@property (nonatomic) uint8_t priority;

@property (nonatomic, copy, nullable) NSString *keyword;
@property (nonatomic, copy, nullable) NSString *headword;
@property (nonatomic, copy, nullable) NSString *entryTitle;
@property (nonatomic, copy, nullable) NSString *anchor;
@property (nonatomic, copy, nullable) NSString *yomiWord;
@property (nonatomic, copy, nullable) NSString *supplementalHeadword;  // synonym for yomiWord
@property (nonatomic, copy, nullable) NSString *sortKey;

@property (nonatomic, readonly, copy, nullable) NSString *displayWord;  // first non-null/non-empty of title, headword, yomi, keyword, in that order


// Copies fields from the other index entry into this one.
// If a key in other is already present here, our value is overwritten if the value in other is a nonempty string.
// Otherwise, in conflict, our value wins.
-(void)mergeIndexEntry:(DSIndexEntry *)other;

@end


NS_ASSUME_NONNULL_END
