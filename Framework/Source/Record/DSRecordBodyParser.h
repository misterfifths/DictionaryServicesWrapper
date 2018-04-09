// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSMutableDictionaryWrapper.h"
#import "DSDefines.h"

@class DSRecordSubEntry;
@class DSRecordSubEntrySense;


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(DSRecord.BodyParser)
@interface DSRecordBodyParser : NSObject

// Understands a variety of XML elements from record bodies, and turns them into a nicer
// format. Intended to parse the other end of keyword index anchors, and other such things
// extracted via XPath.
// Almost certainly only works for NOAD.
// Totally ad hoc; may not give you what you want at all and will probably just assert.
// It does the right thing for most naughty words, though, which is what's truly important.
+(NSArray<DSRecordSubEntry *> *)parseSubEntryFragment:(NSXMLElement *)elem DS_WARN_UNUSED_RESULT;

@end


@interface DSRecordSubEntry : DSMutableDictionaryWrapper<NSString *, id>

// If this subentry is for a related word or phrase, that will hopefully wind up here.
// E.g.: If you parse the particular XML fragment of the "get" entry that contains the
// definition for "get off", this will contain "get off".
// If this is missing, it's likely the subentry is a subsense of the root word of the
// body (with no spelling changes) and you should fall back to that.
@property (nonatomic, copy, nullable) NSString *word;
@property (nonatomic, copy, nullable) NSString *languageNotes;  // "derogatory", "chiefly British", &c.
@property (nonatomic, copy, nullable) NSString *pronunciation;
@property (nonatomic, copy, nullable) NSString *partOfSpeech;
@property (nonatomic, copy, nullable) NSArray<DSRecordSubEntrySense *> *senses;

@end


@interface DSRecordSubEntrySense : DSMutableDictionaryWrapper<NSString *, NSString *>

@property (nonatomic, copy, nullable) NSString *languageNotes;
@property (nonatomic, copy, nullable) NSString *definition;  // nil if this is a particularly boring subsense, esp. ones that are just listings of the other parts of speech. Viz. the entry for "belles-lettres"
@property (nonatomic, copy, nullable) NSString *example;  // usage example. If there are more than one they seem to be separated by "|"

@end


NS_ASSUME_NONNULL_END
