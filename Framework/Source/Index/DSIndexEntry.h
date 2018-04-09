// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSMutableDictionaryWrapper.h"
#import "DSDefines.h"
#import "DSConstants.h"


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(DSIndex.Entry)
@interface DSIndexEntry : DSMutableDictionaryWrapper<DSIndexFieldName, id>

@property (nonatomic) DSBodyDataID externalBodyID;

@property (nonatomic) uint64_t privateFlag;

// These two are computed via bitmasks from the privateFlag
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

@end


NS_ASSUME_NONNULL_END
