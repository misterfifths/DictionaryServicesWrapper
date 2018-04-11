// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import <Foundation/Foundation.h>
#import "DSDefines.h"

@class DSXSLArguments;


NS_ASSUME_NONNULL_BEGIN


@interface NSXMLNode (DSHelpers)

// Mimics what the framework does internally to make a pretty string from the contents of a
// document. Involves collapsing some whitespace and a few other arcane things.
@property (nonatomic, readonly, copy) NSString *ds_sanitizedText;

@end


@interface NSXMLElement (DSUtils)

-(BOOL)ds_attributeForName:(NSString *)attributeName containsToken:(NSString *)token DS_WARN_UNUSED_RESULT;
-(BOOL)ds_hasClass:(NSString *)token DS_WARN_UNUSED_RESULT;


-(nullable NSArray<NSXMLElement *> *)ds_childElementsWithAttributeForName:(NSString *)attributeName
                                                          containingToken:(NSString *)token DS_WARN_UNUSED_RESULT;
-(nullable NSArray<NSXMLElement *> *)ds_childElementsWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;


// any number of matches ok; returns nil if none found
-(nullable NSXMLElement *)ds_firstChildElementWithAttributeForName:(NSString *)attributeName
                                                   containingToken:(NSString *)token DS_WARN_UNUSED_RESULT;
-(nullable NSXMLElement *)ds_firstChildElementWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;


// only one match is ok; asserts in any other case
-(NSXMLElement *)ds_singleChildElementWithAttributeForName:(NSString *)attributeName
                                           containingToken:(NSString *)token DS_WARN_UNUSED_RESULT;
-(NSXMLElement *)ds_singleChildElementWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;


// zero or one matches ok, otherwise asserts
-(nullable NSXMLElement *)ds_optionalSingleChildElementWithAttributeForName:(NSString *)attributeName
                                                            containingToken:(NSString *)token DS_WARN_UNUSED_RESULT;
-(nullable NSXMLElement *)ds_optionalSingleChildElementWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;


// minMatchingChildren <= n <= maxMatchingChildren matches are ok
// otherwise asserts.
// nil if none found (and minMatchingChildren == 0)
// maxMatchingChildren == 0 means "no max"
-(nullable NSXMLElement *)ds_firstChildElementWithAttributeForName:(NSString *)attributeName
                                                   containingToken:(NSString *)token
                                               minMatchingChildren:(NSUInteger)minMatchingChildren
                                               maxMatchingChildren:(NSUInteger)maxMatchingChildren DS_WARN_UNUSED_RESULT;


-(nullable NSXMLElement *)ds_nearestPreviousSiblingWithAttributeForName:(NSString *)attributeName
                                                        containingToken:(NSString *)token DS_WARN_UNUSED_RESULT;
-(nullable NSXMLElement *)ds_nearestPreviousSiblingWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;


// If self has the given class, returns a single-element array with self in it.
// Otherwise, returns all matching children, or nil if none match.
-(nullable NSArray<NSXMLElement *> *)ds_selfOrChildrenWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;

// Returns self or the single matching child. If none match, asserts.
-(NSXMLElement *)ds_selfOrSingleChildWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;

// Returns self or the single matching child. If none match, returns nil.
-(nullable NSXMLElement *)ds_selfOrOptionalSingleChildWithClass:(NSString *)token DS_WARN_UNUSED_RESULT;

@end


@interface NSXMLDocument (DSHelpers)

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSL:(NSXMLDocument *)xslDoc
                                    arguments:(DSXSLArguments *)xslArguments DS_WARN_UNUSED_RESULT;

-(NSXMLDocument *)ds_XMLDocumentByApplyingXSLs:(NSArray<NSXMLDocument *> *)xslDocs
                                     arguments:(DSXSLArguments *)xslArguments DS_WARN_UNUSED_RESULT;

-(NSArray<NSString *> *)ds_nonEmptyTrimmedStringValuesForXPath:(NSString *)xpath DS_WARN_UNUSED_RESULT;

// TODO: this curently mutates the document...
-(NSString *)ds_canonicalXMLStringIncludingContentType:(BOOL)includeContentType DS_WARN_UNUSED_RESULT;

// Compares the result of -canonicalXMLStringPreservingComments:YES
-(BOOL)ds_isEffectivelyEqualToXMLDocument:(NSXMLDocument *)other DS_WARN_UNUSED_RESULT;

@end


@interface DSXMLUtils : NSObject

// Concatentates with spaces the ds_sanitizedText of the given elements.
// Returns empty string if there are no elements.
+(NSString *)sanitizedConcatenatedStringValueOfElements:(NSArray<NSXMLElement *> *)elems DS_WARN_UNUSED_RESULT;

@end


NS_ASSUME_NONNULL_END
