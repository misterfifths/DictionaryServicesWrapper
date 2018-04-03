// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>

@class DSDictionaryXSLArguments;


// feels wrong to import DSCommon here
#pragma push_macro("DS_WARN_UNUSED_RESULT")
#define DS_WARN_UNUSED_RESULT __attribute__((warn_unused_result))


NS_ASSUME_NONNULL_BEGIN


@interface NSXMLDocument (DSHelpers)

// Mimics what the framework does internally to make a pretty string from the contents of a
// document. Involves collapsing some whitespace and a few other arcane things.
@property (nonatomic, readonly, copy) NSString *ds_sanitizedText;

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSL:(NSXMLDocument *)xslDoc
                                    arguments:(DSDictionaryXSLArguments *)xslArguments DS_WARN_UNUSED_RESULT;

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSLs:(NSArray<NSXMLDocument *> *)xslDocs
                                     arguments:(DSDictionaryXSLArguments *)xslArguments DS_WARN_UNUSED_RESULT;

-(NSArray<NSString *> *)ds_nonEmptyTrimmedStringValuesForXPath:(NSString *)xpath DS_WARN_UNUSED_RESULT;

-(BOOL)ds_replaceCSSPlaceholderWithContent:(NSString *)css;

// TODO: this curently mutates the document...
-(NSString *)ds_canonicalXMLStringIncludingContentType:(BOOL)includeContentType DS_WARN_UNUSED_RESULT;

// Compares the result of -canonicalXMLStringPreservingComments:YES
-(BOOL)ds_isEffectivelyEqualToXMLDocument:(NSXMLDocument *)other DS_WARN_UNUSED_RESULT;

@end


NS_ASSUME_NONNULL_END

#pragma pop_macro("DS_WARN_UNUSED_RESULT")
