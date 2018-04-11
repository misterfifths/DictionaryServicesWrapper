// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.

#import "DSRecordBodyParser.h"
#import "DSXMLUtils.h"
#import "DSMutableDictionaryWrapperUtils.h"


static NSString * const DSLanguageNotesKey = @"languageNotes";
static NSString * const DSDefinitionKey = @"definition";
static NSString * const DSExampleKey = @"example";
static NSString * const DSWordKey = @"word";
static NSString * const DSPronunciationKey = @"pronunciation";
static NSString * const DSPartOfSpeechKey = @"partOfSpeech";
static NSString * const DSSensesKey = @"senses";


@implementation DSRecordSubEntrySense

DS_MDW_SharedKeySetImpl(DSLanguageNotesKey, DSDefinitionKey, DSExampleKey);

DS_MDW_StringPropertyImpl(languageNotes, setLanguageNotes, DSLanguageNotesKey);
DS_MDW_StringPropertyImpl(definition, setDefinition, DSDefinitionKey);
DS_MDW_StringPropertyImpl(example, setExample, DSExampleKey);

@end


@implementation DSRecordSubEntry

DS_MDW_SharedKeySetImpl(DSWordKey, DSLanguageNotesKey, DSPronunciationKey, DSPartOfSpeechKey, DSSensesKey);

DS_MDW_StringPropertyImpl(word, setWord, DSWordKey);
DS_MDW_StringPropertyImpl(languageNotes, setLanguageNotes, DSLanguageNotesKey);
DS_MDW_StringPropertyImpl(pronunciation, setPronunciation, DSPronunciationKey);
DS_MDW_StringPropertyImpl(partOfSpeech, setPartOfSpeech, DSPartOfSpeechKey);
DS_MDW_ArrayPropertyImpl(senses, setSenses, DSSensesKey);

@end


@implementation DSRecordBodyParser

+(DSRecordSubEntry *)parse_x_xoh_xdh:(NSXMLElement *)headerElem
{
    // there are some interesting super-condensed versions of these tags:
    // <span role="text" class="posg x_xdh">noun</span>
    // <span class="x_xoh l">the word</span>
    // which is to say, it looks like this can either have nested elements, one per attribute, or,
    // if there's only one attribute of interest, just one element with the classes all condensed onto it.

    DSRecordSubEntry *res = [DSRecordSubEntry new];


    NSString *word = [headerElem ds_selfOrOptionalSingleChildWithClass:@"l"].ds_sanitizedText;
    if(word.length > 0) res.word = word;

    NSArray *lgNotesElems = [headerElem ds_selfOrChildrenWithClass:@"lg"];
    NSString *lgNotes = [DSXMLUtils sanitizedConcatenatedStringValueOfElements:lgNotesElems];
    if(lgNotes.length > 0) res.languageNotes = lgNotes;

    NSString *pronunciation = [headerElem ds_selfOrOptionalSingleChildWithClass:@"pr"].ds_sanitizedText;
    if(pronunciation.length > 0) res.pronunciation = pronunciation;

    NSString *partOfSpeech = [headerElem ds_selfOrOptionalSingleChildWithClass:@"posg"].ds_sanitizedText;
    if(partOfSpeech.length > 0) res.partOfSpeech = partOfSpeech;


    if(res.count == 0) {
        NSLog(@"Got nothing out of a header:\n%@", headerElem.XMLString);
    }

    return res;
}

+(nullable DSRecordSubEntrySense *)parse_x_xo2:(NSXMLElement *)senseElem
{
    DSRecordSubEntrySense *res = [DSRecordSubEntrySense new];

    NSArray *lgNotesElems = [senseElem ds_childElementsWithClass:@"lg"];  // TODO: sometimes there are also "gg" nodes, with grammar notes
    NSString *lgNotes = [DSXMLUtils sanitizedConcatenatedStringValueOfElements:lgNotesElems];
    if(lgNotes.length > 0) res.languageNotes = lgNotes;

    NSString *def = [senseElem ds_optionalSingleChildElementWithClass:@"df"].ds_sanitizedText;
    if(def.length > 0) res.definition = def;
    else {
        // If there's no df, check for an xrg
        // These are definitions-by-way-of-cross-references, like, e.g., "cracker"
        def = [senseElem ds_optionalSingleChildElementWithClass:@"xrg"].ds_sanitizedText;
        if(def.length > 0) res.definition = def;
    }


    NSArray *exampleElems = [senseElem ds_childElementsWithClass:@"eg"];
    NSString *example = [DSXMLUtils sanitizedConcatenatedStringValueOfElements:exampleElems];
    if(example.length > 0) res.example = example;


    // It happense (e.g. "hoer") that these are completely empty sometimes
    return res.count > 0 ? res : nil;
}

+(nullable DSRecordSubEntrySense *)parse_msDict:(NSXMLElement *)elem
{
    /*
     msDict
         lg
         df
         eg
         no l -- these are subsenses; word is in a previous sibling header, or the root of the document

     interchangeable with an x_xo2? sometimes those two classes are on the same element
     */

    return [self parse_x_xo2:elem];
}

+(DSRecordSubEntry *)headerForElement:(NSXMLElement *)elem
                     considerChildren:(BOOL)considerChildren
                     considerSiblings:(BOOL)considerSiblings
{
    static BOOL (^isGarbageHeader)(NSXMLElement *) = ^(NSXMLElement *headerElem) {
        if(!headerElem) return YES;
        return [headerElem ds_hasClass:@"ty_label"];  // numbers for subentries look like this
    };

    NSXMLElement *headerElem = nil;

    if(considerChildren) {
        headerElem = [elem ds_optionalSingleChildElementWithClass:@"x_xoh"];
        if(isGarbageHeader(headerElem)) headerElem = [elem ds_optionalSingleChildElementWithClass:@"x_xdh"];
    }

    if(considerSiblings) {
        if(isGarbageHeader(headerElem)) headerElem = [elem ds_nearestPreviousSiblingWithClass:@"x_xoh"];
        if(isGarbageHeader(headerElem)) headerElem = [elem ds_nearestPreviousSiblingWithClass:@"x_xdh"];
    }

    if(isGarbageHeader(headerElem)) {
        //        NSLog(@"Couldn't find a header for element! Assuming it's top-level.");
        return [DSRecordSubEntry new];
    }

    return [self parse_x_xoh_xdh:headerElem];
}

+(NSArray<DSRecordSubEntry *> *)parseSubEntryFragment:(NSXMLElement *)elem
{
    // the entry for "hell" is a rich source of examples of this XML structure

    /*
     subEntry x_xo1
         x_xoh
             l (word/phrase)
             lg (language notes)
             pr (pronunciation)
             posg (part of speech)
             (sometimes, if are is only an l, this is all rolled into one tag)
         x_xo2 (zero or more)
             lg
             df (definition)
             eg (example)
             (sometimes (e.g., "hoer"), this node is present but entirely empty)


     other times we just get handed a list of x_xo2s or msDicts. can try to reconstruct the related word by
     traversing siblings backwards to find an x_xoh


     sometimes we see this (e.g., "Siwash")...

     x_xd0
         x_xdh (seemingly a synonym for x_xoh)
         x_xd1 (zero or more - no interesting content per se, just holds msDicts)
             msDict x_xd1sub (one per x_xd1?)
     */


    if(![elem ds_hasClass:@"subEntry"]) {
        /*
         Alright, if we're not a subEntry directly, we understand these alternatives:
         1. We're an msDict. Parse ourself as a sense, search backwards to try to find our header, and merge the two.
         2. We're a container with direct subEntry children. Return an array of each of those, parsed.
         3. We're a container with direct msDict children. Parse those as senses, look inside ourself for a header (or backwards *from* ourself, if that fails), and merge all that.
         4. We're an x_xd0. We have a child header, and zero or more x_xd1 children, which themselves have msDict children. Collect the msDicts, parse them, and combine with our header child.
         */

        // Case 1
        if([elem ds_hasClass:@"msDict"]) {
            DSRecordSubEntry *header = [self headerForElement:elem considerChildren:NO considerSiblings:YES];

            DSRecordSubEntrySense *sense = [self parse_msDict:elem];
            if(sense) header.senses = @[ sense ];

            return @[ header ];
        }

        // Case 2
        NSArray<NSXMLElement *> *subEntryChildren = [elem ds_childElementsWithClass:@"subEntry"];
        if(subEntryChildren.count > 0) {
            NSMutableArray<DSRecordSubEntry *> *res = [NSMutableArray arrayWithCapacity:subEntryChildren.count];
            for(NSXMLElement *subEntryChild in subEntryChildren) {
                [res addObjectsFromArray:[self parseSubEntryFragment:subEntryChild]];
            }

            return res;
        }

        // Case 3
        NSArray<NSXMLElement *> *msDictChildren = [elem ds_childElementsWithClass:@"msDict"];
        if(msDictChildren.count > 0) {
            DSRecordSubEntry *header = [self headerForElement:elem considerChildren:YES considerSiblings:YES];

            NSMutableArray *senses = [NSMutableArray arrayWithCapacity:msDictChildren.count];
            for(NSXMLElement *msDictChild in msDictChildren) {
                DSRecordSubEntrySense *sense = [self parse_msDict:msDictChild];
                if(sense) [senses addObject:sense];
            }

            if(senses.count > 0) header.senses = senses;

            return @[ header ];
        }

        // Case 4
        if([elem ds_hasClass:@"x_xd0"]) {
            DSRecordSubEntry *header = [self headerForElement:elem considerChildren:YES considerSiblings:NO];

            NSMutableArray *senses = [NSMutableArray new];

            // We have x_xd1 children...
            NSArray<NSXMLElement *> *x_xd1Children = [elem ds_childElementsWithClass:@"x_xd1"];
            for(NSXMLElement *x_xd1Child in x_xd1Children) {
                // that themselves have msDict children...
                NSArray<NSXMLElement *> *msDictChildren = [x_xd1Child ds_childElementsWithClass:@"msDict"];

                for(NSXMLElement *msDictChild in msDictChildren) {
                    DSRecordSubEntrySense *sense = [self parse_msDict:msDictChild];
                    if(sense) [senses addObject:sense];
                }
            }

            if(senses.count > 0) header.senses = senses;

            return @[ header ];
        }

        // Otherwise, we don't understand this.
        NSAssert(NO, @"Unknown subsense structure!");
    }


    // We understand subEntry elems with an x_xoh child and one or more x_xo2 children.

    DSRecordSubEntry *parsedHeader = [self headerForElement:elem considerChildren:YES considerSiblings:NO];

    NSArray<NSXMLElement *> *sensesElems = [elem ds_childElementsWithClass:@"x_xo2"];

    // boring entries. see, e.g., belles-lettres
    if(sensesElems.count == 0) return @[ parsedHeader ];


    NSMutableArray *senses = [NSMutableArray arrayWithCapacity:sensesElems.count];
    for(NSXMLElement *senseElem in sensesElems) {
        DSRecordSubEntrySense *sense = [self parse_x_xo2:senseElem];
        if(sense) [senses addObject:sense];
    }

    if(senses.count > 0) parsedHeader.senses = senses;

    return @[ parsedHeader ];
}

@end

