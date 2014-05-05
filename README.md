Purpose
--------------

BaseModel provides a base class for building model objects for your iOS or Mac OS projects. It saves you the hassle of writing boilerplate code, and encourages good practices by reducing the incentive to cut corners in your model implementation.

The BaseModel object uses property lists and the NSCoding protocol for serialisation. It is not designed for use with Core Data, although in principle the class could be extended to work with Core Data if needed by changing the BaseModel superclass to an NSManagedObject.

BaseModel is really designed as an *alternative* to Core Data for developers who prefer to have a little more control over the implementation of their data stack. BaseModel gives you precise control over the location and serialisation of your data files, whilst still proving enough automatic behaviour to save you from writing the same code over and over again.

BaseModel is designed to work with the following serialization libraries:

* HRCoder (https://github.com/nicklockwood/HRCoder). HRCoder provides an alternative mechanism for loading and saving data in a human readable/editable format. HRCoder allows you to specify your data files in a standard format, and avoids the need for you to override the `setWith...` methods. Use of HRCoder is completely optional. For an example of how this works, check out the *HRTodoList* example.

* CryptoCoding library (https://github.com/nicklockwood/CryptoCoding). When used in conjunction with CryptoCoding, BaseModel objects support automatic AES encryption of the entire object when saved or loaded to disk. Use of CryptoCoding is completely optional. For an example of how it works, check out the *CryptoTodoList* example.

* FastCoding (https://github.com/nicklockwood/FastCoding). FastCoding provides an alternative mechanism for loading and saving data in a fast, compact binary format. FastCoding is a replacement for NSCoding that produces files tat at 50% of the size, and load in half the time as ordinary NScoded archives. Use of FastCoding is completely optional. For an example of how this works, check out the *FCTodoList* example.

**Note:** HRCoder and CryptoCoding both take advantage of BaseModel's NSCoding implementation and will call the `setWithCoder:` and `encodeWithCoder:` methods. FastCoding uses its own serialization implementation and does not use these methods.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 7.1 / Mac OS 10.9 (Xcode 5.1, Apple LLVM compiler 5.1)
* Earliest supported deployment target - iOS 5.0 / Mac OS 10.7
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

As of version 2.4, BaseModel requires ARC. If you wish to use BaseModel in a non-ARC project, just add the -fobjc-arc compiler flag to the BaseModel.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click BaseModel.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in BaseModel.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including BaseModel.m) are checked.


Thread Safety
--------------

BaseModel instances can be safely created and accessed concurrently from multiple threads, however some BaseModel operations are synchronized on a per-class basis, so creating BaseModel instances or accessing the shared instance concurrently on multiple threads may lead to unexpected performance issues.


Installation
--------------

To use the BaseModel class in your project, just drag the BaseModel.h and .m files into your project. BaseModel has no required dependencies, however you may wish to also include the optional HRCoder (https://github.com/nicklockwood/HRCoder), CryptoCoding (https://github.com/nicklockwood/CryptoCoding) and/or FastCoding (https://github.com/nicklockwood/FastCoding) libraries to enable additional BaseModel functionality.


Classes
--------------

There is a single class, BaseModel which you should use as the base class for any model-type classes. BaseModel provides a core set of functions for dealing with model data, and through the BaseModel protocol, provides hooks to implement additional bespoke behaviours with minimal coding.


Methods
---------------

The BaseModel class has the following methods:

    - (void)setUp;
    
BaseModel's initialisation routine is quite complex and follows a multi-step process. To simplify configuration, BaseModel provides a `setUp` method that is called before anything else so you can pre-configure your instance. This is called only after a successful `[super init]`, so there is no need to verify that self is not nil or call `[super setUp]` (unless you are subclassing one of your own BaseModel subclasses). Like `init`, `setUp` is called only once at the start of the lifetime of an instance, so it is safe to set properties without releasing their existing values (relevant only if you are not using ARC). You should never call `setUp` yourself directly, except in the context of calling `[super setUp]` when subclassing your own BaseModel subclasses.

    - (void)tearDown;
    
The tearDown method complements setUp. It is called whent he object is destroyed, but will only be called if the setUp method was called first. This is useful in situations where the class gets destroyed before it is initialised, which might for example happen if it was created by calling [[Model alloc] initWithObject:nil]. By putting your destructor logic in tearDown instead of dealloc, you can avoid unbalanced calls to removeObserver, etc. You should never call `tearDown` yourself directly, except in the context of calling `[super tearDown]` (it is called automatically by BaseModel's `dealloc` method).  There is no need to call `[super tearDown]` unless you have subclassed one of your own BaseModel subclasses. 

    - (void)setWithDictionary:(NSDictionary *)dict;

If you are initializing your BaseModel instance using a dictionary (typically loaded from JSON or a Plist file) then this method will be called automatically. BaseModel provides a default implementation of `setWithDictionary:` that attempts to set the properties of your class automatically from the dictionary that is passed in, but you can override this if neccesary (e.g. if the property names or types don't match up exactly).

    - (NSDictionary *)dictionaryRepresentation;
    
This method returns a dictionary containing all the (non-nil) properties of the model. This is a useful way to transform a model that was initialized from a Plist or JSON file back into a form that can be saved out as such a file. Note: There is no guarantee that the objects in this dictionary are Plist-safe, so if you intend to generate a Plist or JSON file, you may be better off using the HRCoding library, which can automatically convert child objects to Plist/JSON-safe form recursively.

    - (void)setWithXXX:(XXX *)xxx;
    
BaseModel instances can be initialized with objects of any type, via the `instanceWithObject:`/`initWithObject:` method. To support a given object type, simply add a method `setWith[ClassName]:` where ClassName is the class of the object being set. For example to initialise your BaseModel using an NSArray, add a method setWithArray:` or `setWithNSArray:` and it will be called automatically.

    - (void)setWithCoder:(NSCoder *)aDecoder;
    
This method is called by `initWithCoder:` as part of the NSCoding implementation. BaseModel provides an automatic implementation of NSCoding by inspecting the properties of your class, so there is no need to implement this method yourself unless you need to customise the decoding behaviour. This method is called after the `setUp` method and potentially may be called after default values have been loaded using `setWith[ClassName]:`, so you should not assume that class properties and ivars do not already have values at the point when this method is called.

    - (void)encodeWithCoder:(NSCoder *)aCoder;

The BaseModel class provides an automatic default implementation of this method by inspecting the properties of your class, so there is no need to implement this method yourself unless you need to customise the decoding behaviour.

    + (instancetype)instance;
    - (instancetype)init;
    
Creates an autoreleased instance or initialises a retained instance of the class respectively. These methods will first call `setUp`, and will then attempt to initialise the class from `resourceFile` if that file exists.
    
    + (instancetype)instanceWithObject:(NSDictionary *)dict;
    - (instancetype)initWithObject:(NSDictionary *)dict;
    
Creates an instance of the class and initialises it using the supplied object. This is useful when loading a model from an embedded property list file in the application bundle, or creating model objects from JSON data returned by a web service. This method requires that an appropriate setter method is defined on your class, where the setter name is of the form `setWith[ClassName]:`. For example, to initialise the model using an NSArray, your BaseModel subclass must have a method called `setWithArray:`. This method will attempt to initialise the class from `resourceFile` (if that file exists) prior to calling `setWith[ClassName]:`, so if your resourceFile contains a serialised object, this method will be called twice (with different input).
    
    + (NSArray *)instancesWithArray:(NSArray *)array;

This is similar to calling `instanceWithObject:` with an array parameter, but instead of initialising the object with an array, it iterates over each item in the array and creates an instance from each object by calling `instanceWithObject:` for each array element. The resultant BaseModel instances are then returned as a new array.

    + (instancetype)instanceWithCoder:(NSCoder *)decoder;
    - (instancetype)initWithCoder:(NSCoder *)decoder;

Initialises the object from an NSCoded archive using the NSCoding protocol. This method requires the `setWithCoder:` method to be defined on your subclass. This method will attempt to initialise the class from `resourceFile` (if that file exists) prior to calling `setWithCoder:`, which allows you to first initialise your object with a static data file before loading additional properties from an NSCoded archive.

    + (instancetype)instanceWithContentsOfFile:(NSString *)filePath;
    - (instancetype)initWithContentsOfFile:(NSString *)filePath;
    
Creates/initialises an instance of the model class from a file. If the file is a property list then the model will be initialised using the appropriate `setWith[ClassName]:` method, depending on the type of the root object in the Plist. If the file is an NSCoded archive of an instance of the model then the object will be initialised using `setWithCoder:`. If the file format is not recognised, or the appropriate setWith... function is not implemented, the method will return nil.

    + (instancetype)sharedInstance;

This returns a shared instance of the model object, so any BaseModel subclass can easily be used as a 'singleton' via this method. The shared instance is created lazily the first time it is called, so this functionality has no overhead until it is used. The shared instance is created by first calling `setUp` and then attempting to load first the file specified by the `resourceFile` method and finally the file specified by`saveFile`, so your instance may be initialised up to three times from different sources.

    + (BOOL)hasSharedInstance;
    
Because `sharedInstance` is a lazy constructor, you cannot call it to test if a given class has a shared instance or not. The `hasSharedInstance` method lets you check whether a given model has a shared instance without accidentally creating one.

    + (void)setSharedInstance:(BaseModel *)instance;

This method lets you replace the current shared instance with another instance of the model. This is useful for models that may be re-loaded from a file or downloaded from a web service. The previous shared instance will be autoreleased when the new one is set. Note that since the shared model instance is replaced, any objects hanging on to references to the model will need to be updated. The model broadcasts a `BaseModelSharedInstanceUpdatedNotification` via NSNotificationCenter whenever this method is called, so setting an observer for that event is a good way to make sure that any retained references are updated. You can also set the BaseModel shared instance to nil in order to reclaim memory for BaseModel shared instances if they are no longer needed, or in the event of a memory warning.

    + (void)reloadSharedInstance;

This method reloads the shared instance of the model using the file specified by `saveFile`. This method replaces the sharedInstance by calling `setSharedInstance:` internally, so the same notes apply regarding updating references.

    - (BOOL)writeToFile:(NSString *)path format:(BMFileFormat)format atomically:(BOOL)atomically;

This method attempts to serialise the model object to the specified file using the specified format. If you select anything other than BMFileFormatKeyedArchive as the format, you will need to include the requisite library in your project, otherwise using this will throw an exception. The path can be absolute or relative. Relative paths will be automatically prefixed with `~/Library/Application Support/`. Returns YES on success or NO on failure.

    - (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;

This method attempts to serialise the model object to the specified file using the format specified by the +saveFormat method. The path can be absolute or relative. Relative paths will be automatically prefixed with `~/Library/Application Support/`. Returns YES on success or NO on failure.

    + (NSString *)newUniqueIdentifier;
    
This method is used to generate a new, globally unique identifier. Each time it is called it uses the CFUUID APIs to create a brand new value that will never be repeated on any device. You can store this value in a property in your model to give it a unique identifier suitable for maintaining references to the object when it is loaded and saved. Note however that responsibility for loading, saving and copying this ID is left to the developer. If you do not preserve this value when saving and loading your model then it will be different each time the object is re-instantiated.

    + (NSString *)resourceFile;

This method returns the filename for a file to be used to initialise every instance of the object. This would typically be a property list file stored in the application bundle, and is a fantastic way to quickly define complex default data sets for model objects without having to hard-code them in the `setUp` method. This can be a full or partial path name. Partial paths will be treated as being relative to the application bundle resources folder. The default return value for this method is *ClassName.plist* where ClassName is the name of the model class, but you can override this method in your own subclasses to change the file name.

In case you are wondering, there is a small overhead to loading this file the first time you create an instance of your model, however the file is cached and re-used for subsequently created model instances where possible. For models that have no initialisation file, just make sure that no file called *ClassName.plist* exists in the bundle, and no initialisation will take place. It is not necessary to override this method and return nil, unless you need to have a resource file called *ClassName.plist* that isn't being used for this purpose (in which case you should probably just rename your file).

    + (NSString *)saveFile;

This method returns a path for a file to be used to load and save the shared instance of the class. By default this method returns *ClassName.extension* where ClassName is the name of the model class and 'extension' is either 'plist', 'json' or 'fast', depending on the format specified in the +saveFormat method. you can override this method in your own subclasses to change the filename or specify an explicit directory. If you specify a relative filename or path rather than absolute, it will be automatically prefixed with `~/Library/Application Support/`.

    + (BMFileFormat)saveFormat;

This method returns the file format to use for saving the shared instance of the class. By default, this method returns BMFileFormatKeyedArchive, which means that the model will be saved and loaded using the NSKeyedArchiver/NSKeyedUnarchiver and the NSCoding protocol, but you can override this method in your own subclasses to change the file type. BaseModel supports a number of alternative serialisation formats by taking advantage of additional libraries such as CryptoCoding, FastCoding and HRCoder. See BMFileFormat options below.

    - (BOOL)save;

Attempts to save the model, and returns YES if successful or NO if saving fails. This method checks to see if the instance being saved is the shared instance. If so, it will save to the file specified by the `saveFile` method by using the NSCoding protocol and calling `encodeWithCoder:`. If the instance is not the shared instance it will throw an exception. You can override the save method in your subclasses to provide an implementation for saving individual models. There are a couple of approaches (which is why there is no default implementation):

1. If the instance is a member of a larger object graph, where the root node is another BaseModel of the same or different type, you could modify the save method to call `save` on the root node, that way the entire tree can be saved by calling `save` on any node:

        - (void)save
        {
            [[RootModel sharedInstance] save];
        }
    
2. You could implement your own logic to save the class to a file using the `writeToFile:` method with a custom file path:

        - (void)save
        {
            [self writeToFile:@"some-unique-filename.plist" atomically:YES];
        }
        
    You can then load the file again later using:

        MyModel *instance = [MyModel instanceWithContentsOfFile:@"some-unique-filename.plist"];


BMFileFormat Options
----------------------

BaseModel can save files in a number of different formats. The default is NSKeyedArchiver, but there are some other choices, each with different strengths and weaknesses.

    BMFileFormatKeyedArchive

This is the default save format. This saves the model as a binary-coded property list using NSKeyedArchiver. BaseModel fully supports NSCoding, so this option allows you to save more-or-less any type of object without any additional effort on your part. The only exception is if you need to save properties that are structs, or other types not supported by NSCoding, in which case you may need to override encodeWithCoder:/setWithCoder: to handle these cases.

    BMFileFormatXMLPropertyList
    
This saves the model as an XML property list. This differs from the NSCoded file saved by BMFileFormatKeyedArchive because it is human-readabled. This is great for saving data that you want to be able to view or hand-edit in a text editor. XML property lists do not include class information however, so you may need to override the setWithDictionary: method on either your root or child model classes in order to load the resultant file correctly. You may want to consider using the BMFileFormatHRCodedXML option instead, which uses the HRCoder library to produce XML property lists that include the class information.
    
    BMFileFormatBinaryPropertyList
    
This is the same as the BMFileFormatXMLPropertyList option (with the same limitations), but saves the file as a binary property list. This cannot be viewed in a text editor, but can be opened and edited in property list editors, such as the one built into Xcode.

    BMFileFormatJSON
    
This is the similar to the BMFileFormatXMLPropertyList option (with the same limitations), but saves the data as a JSON file.
   
    BMFileFormatUserDefaults
    
This is the same as the BMFileFormatBinaryPropertyList option, except that when calling the save method, instead of saving to a file, the model will be saved in [NSUserDefaults standardUserDefaults]. This is a great option for introducing a strongly-typed settings model for your project.

    BMFileFormatKeychain
    
This is the similar to the BMFileFormatBinaryPropertyList option, except that when calling the save method, instead of saving to a file, the model will be securely saved in the keychain (meaning that every property will be individually encoded as a password in the keychain). This is a great option for models that represent user login credentials, or other secure data. Use of this option requires you to include the FXKeychain library. If your object contains classes that are not property list-safe, you will need to enabled the FXKeychain FXKEYCHAIN_USE_NSCODING option, which is off by default on Mac OS (but on by default on iOS). Note that the keychain has limited storage space, so you should not use this for storing large amounts of secure data (for that, try the BMFileFormatCryptoCoding option instead).
    
    BMFileFormatCryptoCoding
    
This option used the CryptoCoding library to save the model using AES encryption. The model is saved using NSCoding before being encrypted, so should work automatically.

    BMFileFormatHRCodedXML
    
This option saves the file as a human-readabled XML property list using the HRCoder library. The file includes all the object class names, so no additional work is required in the setWithDictionary: method in order to load the models again. 
    
    BMFileFormatHRCodedJSON
        
This option saves the file as a human-readabled JSON file using the HRCoder library. The file includes all the object class names, so no additional work is required in the setWithDictionary: method in order to load the models again. 
        
    BMFileFormatHRCodedBinary
    
This option saves the file as a binary property list using the HRCoder library. The file cannot be viewed in a text editor, but if opened with a property list editor (such as the one built into Xcode), it can be read and edited by hand. The file includes all the object class names, so no additional work is required in the setWithDictionary: method in order to load the models again. 

    BMFileFormatFastCoding
    
This option saves the file as a binary file using the FastCoding library. This is similar to a binary property list, but is much faster to save and load, and creates a smaller file on disk. FastCoding works automatically with most property type, the only exception is if you need to save properties that are structs, or other types not supported by KVC, in which case you may need to do some additional work to handle these cases.


Usage
-----------

The BaseModel class is abstract, and is not designed to be instantiated directly. To implement a model object, create a new subclass of the BaseModel class and implement or override the methods that need to be customised for your specific requirements. Look at the *TodoList* project for an example of how to do this.


Release Notes
-------------------

Version 2.6.2

- Fixed bug when serialising sub-objects using FXKeychain

Version 2.6.1

- Fixed infinite loop when -initWithObject: is passed a nil value
- Saving models using the BMFileFormatHRCodedJSON format now works correctly

Version 2.6

- Added tearDown method to complement setUp
- save method now return a BOOL to indicate success
- BaseModel can now automatically serialize to a Property List or JSON file
- BaseModel can now automatically save instances to NSUserDefaults and the keychain
- Added +allPropertyKeys and +codablePropertyKeys public properties
- Passing NSNull to -initWithObject: now returns nil instead of crashing
- returning nil from a BaseModel constructor no longer crashes +instancesWithArray:
- BaseModel now provides a nice default implementation for -debugDescription method

Version 2.5

- Now implements NSCoding (-setWithCoder:, -encodeWithCoder:) automatically, so there is no need to use the AutoCoding library
- Now provides a default implementation of -setWithDictionary: that uses property inspection to map dictionary values to properties automatically
- Added support for the FastCoding protocol for saving/loading models
- Added +saveFormat method as a more convenient way to specify the file format to use for saving
- Improved multithreaded performance by eliminating internal @synchronized calls
- Now complies with the -Weverything warning level

Version 2.4.4

- Fixed warning under Xcode 5

Version 2.4.3

- Added explicit function pointer casts for all obc_msgSend calls.
- atomic argument is now respected when calling -writeToFile:atomically:
- Now complies with the -Wextra warning level

Version 2.4.2

- writeToFile:atomically: now returns a boolean indicating success or failure.

Version 2.4.1

- BaseModel will no longer attempt to treat resource files as JSON unless the file has a "json" or "js" extension
- Added more robust warning if using JSON when targeting platforms that do not support it

Version 2.4

- Added support for loading resource files encoded in JSON format
- BaseModel now requires ARC. See README file for details on how to upgrade
- Removed uniqueID property because it complicates the class interface for no good reason
- Corrected a number of typos and innacuracies in the documentation

Version 2.3.5

- Fixed a bug when creating BaseModel instances that are initialised with a resource file from within the init method of another BaseModel instance.

Version 2.3.4

- Fixed bug in resource file caching mechanism

Version 2.3.3

- Added support for CryptoCoding
- Updated for iOS6 / Xcode 4.5

Version 2.3.2

- It is now possible to set the shared instance of a BaseModel to nil, which allows you to reclaim memory for BaseModel shared instances if they are no longer needed, or in the event of a memory warning.

Version 2.3.1

- Switched constructors to return new type-safe `instancetype` instead of id, making it easier to use dot-syntax property accessors on basemodel singletons.

Version 2.3

- Removed the uniqueID property by default and replaced it with a more flexible `newUniqueIdentifier` class method. To re-enable the uniqueID property, add BASEMODEL_ENABLE_UNIQUE_ID to your project's preprocessor macros

Version 2.2.2

- Added support for the HRCoder library, which provides human-readable object serialisation and de-serialisation using NSCoding

Version 2.2.1

- Fixed minor bug in setter name generation logic
- Removed deprecated property list serialisation methods

Version 2.2

- Added new instancesWithArray: method for loading an array of models in one go.
- Added setWithString:, setWithNumber: and setWithData: methods.
- Replaced instanceWithDictionary/Array: and initWithDictionary/Array: methods and replaced them with instanceWithObject: and initWithObject:

Version 2.1

- Added automatic support for ARC compile targets
- BaseModel is now designed to work hand-in-hand with the AutoCoding library, which provides completely automatic object serialisation via NSCoding
- NSObject (BaseModel) category has now been removed from the BaseModel library. You can now find this functionality in the AutoCoding library instead (https://github.com/nicklockwood/AutoCoding).
- Fixed a bug where `setUp` method could be called multiple times

Version 2.0

- Major API redesign. It is not recommended to update projects that use BaseModel 1.1 or earlier to version 2.0

Version 1.1

- Added mergeValuesFromObject method.
- Renamed documentsPath to savePath.
- Updated loading and saving methods to use the application support folder by default, instead of the documents folder.
- Fixed nil object exception in loading code.
- Fixed bug in NSCoded loading logic.

Version 1.0

- Initial release