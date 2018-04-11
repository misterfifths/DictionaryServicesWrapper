// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
@import DictionaryServicesWrapper;
@import DictionaryServicesWrapper.NSDictionaryWrapperSubclassing;

@class DSRecordSubEntry;


typedef NSString * const WotDEntryKey NS_TYPED_EXTENSIBLE_ENUM;
extern WotDEntryKey WotDEntryKeyHeadword;
extern WotDEntryKey WotDEntryKeyEntryID;
extern WotDEntryKey WotDEntryKeyPOS;
extern WotDEntryKey WotDEntryKeyPronunciation;
extern WotDEntryKey WotDEntryKeySecondaryHeadword;
extern WotDEntryKey WotDEntryKeySense;


NS_ASSUME_NONNULL_BEGIN


@interface WotDEntry : DSMutableDictionaryWrapper<WotDEntryKey, NSString *>

// These two are mandatory. If anything else is missing, the plugin will look up
// the reference and fill in the blanks. See the note in -entryForRecord:byReference:
// for notes on how it bypasses the useless reference index.
@property (nonatomic, copy, nullable) NSString *headword;
@property (nonatomic, copy, nullable) NSString *referenceID;

@property (nonatomic, copy, nullable) NSString *partOfSpeech;
@property (nonatomic, copy, nullable) NSString *secondaryHeadword;  // plugin uses syllabified headword for this in NOAD
@property (nonatomic, copy, nullable) NSString *pronunciation;
@property (nonatomic, copy, nullable) NSString *sense;

+(nullable WotDEntry *)entryForRecordSubEntry:(DSRecordSubEntry *)subEntry ofRecord:(DSRecord *)record;
+(nullable WotDEntry *)entryForRecord:(DSRecord *)record byReference:(BOOL)byReference;

@end


NS_ASSUME_NONNULL_END
