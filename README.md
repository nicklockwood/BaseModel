Purpose
--------------

BaseModel provides a base class for building model objects for your iOS or Mac OS projects. It saves you the hassle of writing boilerplate code, and encourages good practices by reducing the incentive to cut corners in your model implementation.

The BaseModel object uses property lists and the NSCoding protocol for serialisation. It is not designed for use with Core Data, although in principle the class could be extended to work with Core Data if needed by changing the BaseModel superclass to an NSManagedObject.

BaseModel is really designed as an *alternative* to Core Data for developers who prefer to have a little more control over the implementation of their data stack. BaseModel gives you precise control over the location and serialisation of your data files, whilst still proving enough automatic behaviour to save you from writing the same code over and over again.

BaseModel is designed to work with the AutoCoding library (https://github.com/nicklockwood/AutoCoding). It does not require this library to function but when used in combination, BaseModel objects support automatic loading and saving without needing to write your own NSCoding methods. Use of AutoCoding is completely optional. For an example of how it works, check out the *AutoTodoList* example.

BaseModel is also designed to work with the HRCoder library (https://github.com/nicklockwood/HRCoder) as an alternative mechanism for loading and saving data in a human readable/editable format. HRCoder allows you to specify your data files in a standard format, and when used in conjunction with AutoCoding avoids the need for you to write any `setWith...` methods. Use of HRCoder is completely optional. For an example of how this works, check out the *HRTodoList* example.

BaseModel is also designed to work with the CryptoCoding library (https://github.com/nicklockwood/CryptoCoding). It does not require this library to function, but when used in conjunction with CryptoCoding, BaseModel objects support automatic AES encryption of the entire object when saved or loaded to disk. Use of CryptoCoding is completely optional. For an example of how it works, check out the *CryptoTodoList* example.

**Note:** You can combine AutoCoding with either HRCoder or CryptoCoding, or neither. AutoCoding is independent of the coding scheme used.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 6.0 / Mac OS 10.8 (Xcode 4.5.2, Apple LLVM compiler 4.1)
* Earliest supported deployment target - iOS 5.0 / Mac OS 10.7
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

As of version 2.4, BaseModel requires ARC. If you wish to use BaseModel in a non-ARC project, just add the -fobjc-arc compiler flag to the BaseModel.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click BaseModel.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in BaseModel.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including BaseModel.m) are checked.


Thread Safety
--------------

BaseModel instances can be safely created on any thread, however a number of BaseModel operations are synchronized on a per-class basis, so creating BaseModel instances or accessing the shared instance concurrently on multiple threads may lead to unexpected performance issues.


Installation
--------------

To use the BaseModel class in your project, just drag the BaseModel.h and .m files into your project. BaseModel has no required dependencies, however you may wish to also include the optional AutoCoding library (https://github.com/nicklockwood/AutoCoding) to get the full benefits of using BaseModel, and you may also wish to include the HRCoding (https://github.com/nicklockwood/HRCoding) or CryptoCoding (https://github.com/nicklockwood/CryptoCoding) libraries to enable additional BaseModel functionality.


Classes
--------------

There is a single class, BaseModel which you should use as the base class for any model-type classes. BaseModel provides a core set of functions for dealing with model data, and through the BaseModel protocol, provides hooks to implement additional bespoke behaviours with minimal coding.


Optional methods
--------------

The BaseModel class implements the BaseModel protocol, which specifies some optional methods that can be implemented by BaseModel subclasses to extend the functionality. The BaseModel protocol defines the following optional methods:

    - (void)setUp;
    
BaseModel's initialisation routine is quite complex and follows a multi-step process. To simplify configuration, BaseModel provides a `setUp` method that is called before anything else so you can pre-configure your instance. This is called only after a successful `[super init]`, so there is no need to verify that self is not nil or call `[super setUp]` (unless you are subclassing one of your own BaseModel subclasses). Like `init`, `setUp` is called only once at the start of the lifetime of an instance, so it is safe to set properties without releasing their existing values (relevant only if you are not using ARC). You should never call `setUp` yourself directly, except in the context of calling `[super setUp]` when subclassing your own BaseModel subclasses.

    - (void)setWithDictionary:(NSDictionary *)dict;
    - (void)setWithArray:(NSArray *)array;
    - (void)setWithString:(NSString *)string;
    
These methods are used to extend you model with the capability to be initialised from a standard object type (i.e. one that is supported by the Plist format). This is useful as it allows objects to be automatically loaded from a Plist in your application bundle. It could also be used to instantiate objects from other formats like JSON or XML.

These methods are called after the `setUp` method, so you should not assume that class properties and ivars do not already have values at the point when this method is called. If you are not using ARC, be careful to safely release any property values before setting them. **Note:** these methods are defined in the protocol only to help with code autocompletion - it is actually possible to initialise a BaseModel instance with any kind of object if you define an appropriate setup method of the form `setWith[ClassName]:` in your BaseModel subclass.

If you are using the HRCoder library, you probably don't need to implement these methods, provided that you create your data files in the correct format. Files loaded using HRCoder will call the `setWithCoder:` method instead of `setWithDictionary/Array/etc:`.

    - (void)setWithCoder:(NSCoder *)aDecoder;
    
This method is called by `initWithCoder:` as part of the NSCoding implementation. If you are implementing NSCoding serialisation for your class, you should implement this method instead of overriding `initWithCoder:`. This method is called after the `setUp` method and potentially may be called after default values have been loaded using `setWith[ClassName]:`, so you should not assume that class properties and ivars do not already have values at the point when this method is called. Be careful to safely release any property values before setting them. Note that if you are using the AutoCoding library, this method is already implemented for you.

    - (void)encodeWithCoder:(NSCoder *)aCoder;

The BaseModel class can optionally implement the NSCoding protocol methods. If you are implementing NSCoding serialisation for your class, you should implement this method. Note that if you are using the AutoCoding library, this method is already implemented for you.


Methods
---------------

The BaseModel class has the following methods:

    + (instancetype)instance;
    - (instancetype)init;
    
Create an autoreleased instance or initialises a retained instance of the class respectively. These methods will first call `setUp`, and will then attempt to initialise the class from `resourceFile` if that file exists.
    
    + (instancetype)instanceWithObject:(NSDictionary *)dict;
    - (instancetype)initWithObject:(NSDictionary *)dict;
    
Creates an instance of the class and initialises it using the supplied object. This is useful when loading a model from an embedded property list file in the application bundle, or creating model objects from JSON data returned by a web service. This method requires that an appropriate setter method is defined on your class, where the setter name is of the form `setWith[ClassName]:`. For example, to initialise the model using an NSDictionary, your BaseModel subclass must have a method called `setWithDictionary:`. This method will attempt to initialise the class from `resourceFile` (if that file exists) prior to calling `setWith[ClassName]:`, so if your resourceFile contains a serialised object, this method will be called twice (with different input).
    
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

    - (void)writeToFile:(NSString *)path atomically:(BOOL)atomically;

This method attempts to serialise the model object to the specified file using NSCoding. If you are not using the AutoCoding library, you will need to implement the `encodeWithCoder:` method, otherwise using this method will throw an exception. The path can be absolute or relative. Relative paths will be automatically prefixed with `~/Library/Application Support/`.

    - (BOOL)useHRCoderIfAvailable;

Normally, BaseModel saves files using NSCoding and the NSKeyedArchiver, which creates binary property list files in a complex format that is not human-readable or editable. The HRCoder library provides an alternative format for NSCoding that is more similar to an ordinary, hand-written property list file. BaseModel detects the presence of the HRCoder class if it's included in the project and will use it by default if available. If you do not want to use HRCoder for saving a particular model, override this method and return NO. BaseModel is still able to load archives that are encoded using the HRCoding protocol if this method returns NO, but if you save over the original file it will use NSKeyedArchiver.

    + (NSString *)newUniqueIdentifier;
    
This method is used to generate a new, globally unique identifier. Each time it is called it uses the CFUUID APIs to create a brand new value that will never be repeated on any device. You can store this value in a property in your model to give it a unique identifier suitable for maintaining references to the object when it is loaded and saved. Note however that responsibility for loading, saving and copying this ID is left to the developer. If you do not preserve this value when saving and loading your model then it will be different each time the object is re-instantiated.

    + (NSString *)resourceFile;

This method returns the filename for a file to be used to initialise every instance of the object. This would typically be a property list file stored in the application bundle, and is a fantastic way to quickly define complex default data sets for model objects without having to hard-code them in the `setUp` method. This can be a full or partial path name. Partial paths will be treated as being relative to the application bundle resources folder. The default return value for this method is *ClassName.plist* where ClassName is the name of the model class, but you can override this method in your own subclasses to change the file name.

In case you are wondering, there is a small overhead to loading this file the first time you create an instance of your model, however the file is cached and re-used for subsequently created model instances where possible. For models that have no initialisation file, just make sure that no file called *ClassName.plist* exists in the bundle, and no initialisation will take place. It is not necessary to override this method and return nil, unless you need to have a resource file called *ClassName.plist* that isn't being used for this purpose (in which case you should probably just rename your file).

    + (NSString *)saveFile;

This method returns a path for a file to be used to load and save the shared instance of the class. By default this file is defined as *ClassName.plist* where ClassName is the name of the model class, but you can override this method in your own subclasses to change the filename or specify an explicit directory. If you specify a relative filename or path rather than absolute, it will be automatically prefixed with `~/Library/Application Support/`.

    - (void)save;

This method checks to see if the instance being saved is the shared instance. If so, it will save to the file specified by the `saveFile` method by using the NSCoding protocol and calling `encodeWithCoder:`. If the instance is not the shared instance it will throw an exception. You can override the save method in your subclasses to provide an implementation for saving individual models. There are a couple of approaches (which is why there is no default implementation): 

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

Usage
-----------

The BaseModel class is abstract, and is not designed to be instantiated directly. To implement a model object, create a new subclass of the BaseModel class and implement or override the methods that need to be customised for your specific requirements. Look at the *TodoList* project for an example of how to do this.

By using the HRCoder and AutoCoding libraries, and following a conventional format for your configuration files, you can dramatically reduce your development time by eliminating boilerplate code. Compare the *AutoTodoList*, *HRTodoList* to the original *TodoList* project to see how these libraries can reduce setup code in your model objects.