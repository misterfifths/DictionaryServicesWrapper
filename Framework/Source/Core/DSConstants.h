// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>


#define DSStringify(...) #__VA_ARGS__

#define DSExternAlias(type, dsName, dictionaryServicesName) \
    _Pragma(DSStringify(redefine_extname dsName _ ## dictionaryServicesName)) \
    extern type dsName


NS_ASSUME_NONNULL_BEGIN


typedef NSString *DSIndexName NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSIndex.WellKnownName);
extern DSIndexName const DSIndexNameKeyword;
extern DSIndexName const DSIndexNameBodyData;
extern DSIndexName const DSIndexNameReference;


typedef NSString *DSIndexInfoKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSIndexInfo.WellKnownKey);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyName, kIDXPropertyIndexName);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyPath, kIDXPropertyIndexPath);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyAccessMethod, kIDXPropertyIndexAccessMethod);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyKeyMatchingMethods, kIDXPropertyIndexKeyMatchingMethods);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyDataSizeLength, kIDXPropertyIndexDataSizeLength);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyWritable, kIDXPropertyIndexWritable);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeySupportsDataID, kIDXPropertyIndexSupportDataID); // sic
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyBigEndian, kIDXPropertyIndexBigEndian);
DSExternAlias(DSIndexInfoKey const, DSIndexInfoKeyDataFields, kIDXPropertyDataFields);

typedef NSString *DSIndexInfoDataFieldsKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSIndexInfo.WellKnownDataFieldsKey);
DSExternAlias(DSIndexInfoDataFieldsKey const, DSIndexInfoDataFieldsKeyExternalFields, kIDXPropertyExternalFields);
DSExternAlias(DSIndexInfoDataFieldsKey const, DSIndexInfoDataFieldsKeyFixedFields, kIDXPropertyFixedFields);
DSExternAlias(DSIndexInfoDataFieldsKey const, DSIndexInfoDataFieldsKeyVariableFields, kIDXPropertyVariableFields);

typedef NSString *DSIndexFieldInfoKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSIndexField.WellKnownInfoKey);
DSExternAlias(DSIndexFieldInfoKey const, DSIndexFieldInfoKeyName, kIDXPropertyDataFieldName);
DSExternAlias(DSIndexFieldInfoKey const, DSIndexFieldInfoKeyExternalIndexName, kIDXPropertyIndexName);  // sic
DSExternAlias(DSIndexFieldInfoKey const, DSIndexFieldInfoKeyDataSize, kIDXPropertyDataSize);
DSExternAlias(DSIndexFieldInfoKey const, DSIndexFieldInfoKeyDataSizeLength, kIDXPropertyDataSizeLength);


typedef NSString *DSIndexFieldName NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSIndexField.WellKnownName);
extern DSIndexFieldName const DSIndexFieldNameExternalBodyID;
extern DSIndexFieldName const DSIndexFieldNamePrivateFlag;
extern DSIndexFieldName const DSIndexFieldNameKeyword;
extern DSIndexFieldName const DSIndexFieldNameHeadword;
extern DSIndexFieldName const DSIndexFieldNameEntryTitle;
extern DSIndexFieldName const DSIndexFieldNameAnchor;
extern DSIndexFieldName const DSIndexFieldNameYomiWord;
extern DSIndexFieldName const DSIndexFieldNameSortKey;


typedef uint64_t DSIndexFieldPrivateFlagBitmask NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSIndexField.PrivateFlagBitmask);
extern const DSIndexFieldPrivateFlagBitmask DSIndexFieldPrivateFlagBitmaskCensored;
extern const DSIndexFieldPrivateFlagBitmask DSIndexFieldPrivateFlagBitmaskPriority;


typedef NS_ENUM(NSUInteger, DSDefinitionStyle) {
    DSDefinitionStyleBareXHTML,     // XHTML with no included CSS. Filters parental-control stuff and applies dictionary XSL
    DSDefinitionStyleXHTMLForApp,   // XHTML with the app CSS included
    DSDefinitionStyleXHTMLForPanel, // XHTML with the panel CSS included and items with priority="2" excluded
    DSDefinitionStylePlainText,     // Cleaned-up plaintext of DSDefinitionStyleBareXHTML, effectively
    DSDefinitionStyleRaw            // not widely supported... maybe returns an NSData when it is? Applies no XSL; just straight contents of the BodyData idx entry
} NS_SWIFT_NAME(DSDictionary.DefinitionStyle);


// The value for all of these is an NSString, with the exception of DSTextElementKeySenses,
// which is an array of strings.
typedef NSString *DSTextElementKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSRecordTextElements.WellKnownKey);
DSExternAlias(DSTextElementKey const, DSTextElementKeyRecordID, kDCSTextElementKeyRecordID);
DSExternAlias(DSTextElementKey const, DSTextElementKeyHeadword, kDCSTextElementKeyHeadword);
DSExternAlias(DSTextElementKey const, DSTextElementKeySyllabifiedHeadword, kDCSTextElementKeySyllabifiedHeadword);
DSExternAlias(DSTextElementKey const, DSTextElementKeyPartOfSpeech, kDCSTextElementKeyPartOfSpeech);
DSExternAlias(DSTextElementKey const, DSTextElementKeyPronunciation, kDCSTextElementKeyPronunciation);
DSExternAlias(DSTextElementKey const, DSTextElementKeySenses, kDCSTextElementKeySenses);
extern DSTextElementKey const DSTextElementKeyTitle;

DSTextElementKey DSTextElementKeyForOldName(NSString *oldName)
    NS_SWIFT_NAME(DSTextElementKey.init(oldName:));

NSString * __nullable DSOldNameForTextElementKey(DSTextElementKey textElementKey)
    NS_SWIFT_NAME(getter:DSTextElementKey.oldName(self:));


typedef NSString *DSXSLArgumentKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(DSDictionaryXSLArguments.WellKnownKey);
extern DSXSLArgumentKey const DSXSLArgumentKeyParentalControl;
extern DSXSLArgumentKey const DSXSLArgumentKeyAriaLabel;
extern DSXSLArgumentKey const DSXSLArgumentKeyBaseURL;
extern DSXSLArgumentKey const DSXSLArgumentKeyRTLDirection;
extern DSXSLArgumentKey const DSXSLArgumentKeyStylesheetContent;


typedef NSString *DSSearchMethod NS_TYPED_EXTENSIBLE_ENUM;
DSExternAlias(DSSearchMethod const, DSSearchMethodExactMatch, kIDXSearchExactMatch);
DSExternAlias(DSSearchMethod const, DSSearchMethodPrefixMatch, kIDXSearchPrefixMatch);
DSExternAlias(DSSearchMethod const, DSSearchMethodCommonPrefixMatch, kIDXSearchCommonPrefixMatch);
DSExternAlias(DSSearchMethod const, DSSearchMethodWildcardMatch, kIDXSearchWildcardMatch);
DSExternAlias(DSSearchMethod const, DSSearchMethodAllMatch, kIDXSearchAllMatch)  __attribute__((deprecated("Use an empty string with prefix match")));  // Pretty weird & only understood by indexes

NSUInteger DSUIntegerForSearchMethod(DSSearchMethod searchMethod)
    NS_SWIFT_NAME(getter:DSSearchMethod.unsignedIntValue(self:));


NS_ASSUME_NONNULL_END


#undef DSExternAlias
#undef DSStringify
