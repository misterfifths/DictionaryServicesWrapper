// DictionaryServicesWrapper
// 2018 / Tim Clem / github.com/misterfifths
// Public domain.


#define DS_MDW_PropertyImpl(type, getter, setter, key) \
    -(type)getter { return self[key]; } \
    -(void)setter:(type)newValue { self[key] = newValue; } \
    struct dummy

#define DS_MDW_CopyPropertyImpl(type, getter, setter, key) \
    -(type)getter { return self[key]; } \
    -(void)setter:(type)newValue { self[key] = [newValue copy]; } \
    struct dummy

#define DS_MDW_StringPropertyImpl(getter, setter, key) DS_MDW_CopyPropertyImpl(NSString *, getter, setter, key)

#define DS_MDW_ArrayPropertyImpl(getter, setter, key) DS_MDW_CopyPropertyImpl(NSArray *, getter, setter, key)

#define DS_MDW_SharedKeySetImpl(...) \
    +(id)sharedKeySet \
    { \
        static id keySet; \
        static dispatch_once_t onceToken; \
        dispatch_once(&onceToken, ^{ \
            keySet = [NSMutableDictionary sharedKeySetForKeys:@[ __VA_ARGS__ ]]; \
        }); \
        return keySet; \
    } \
    struct dummy
