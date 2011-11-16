Purpose
--------------

BaseModel provides a base class for building model objects for your iOS or Mac OS projects. It saves you the hassle of writing boilerplate code, and encourages good practices by reducing the incentive to cut corners in your model implementation.

The BaseModel object uses plists and the NSCoding protocol for serialisation. It is not designed for use with Core Data, although in principle the class could be extended to work with Core Data if needed by changing the BaseModel superclass to an NSManagedObject.

BaseModel is really designed as an *alternative* to Core Data for developers who prefer to have a little more control over the implementation of their data stack. BaseModel gives you precise control over the location and serialisation of you data files, whilst still proving enough automatic behaviour to save you from writing the same code over and over again.


Supported iOS & SDK Versions
-----------------------------

* Supported build target - iOS 5.0 (Xcode 4.2)
* Earliest supported deployment target - iOS 4.0 (Xcode 4.2)
* Earliest compatible deployment target - iOS 3.0

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


Installation
--------------

To use the BaseModel class in your project, just drag the class files into your project. It has no dependencies.


NSSObject extension methods
-----------------------------

The NSObject(BaseModel) category extends NSObject with the following methods. Since this is a category, every single Cocoa object, including AppKit/UIKit objects and BaseModel instances inherit these methods.

	+ (id)objectWithContentsOfFile:(NSString *)path;
	
This attempts to load the file using the following sequence: 1) If the file is an NSCoded archive, load the object and return it, 2) If the file is a Plist containing an NSDictionary or NSArray, load and return an NSDictionary or NSArray, 3) Load the raw data and return as an NSData object.

There is some caching behaviour built in to this method: NSStrings, NSDictionaries and NSArrays, objects loaded using this method will be cached provided that the object is below a certain size. This allows you to initialise instances of the same BaseModel class multiple times with minimal performance impact as the same object will be returned each time and no filesystem access will take place after the first instance is loaded.
	
	- (void)writeToFile:(NSString *)filePath atomically:(BOOL)useAuxiliaryFile;
	
This attempts to write the file to disk. This method is overridden by the equivalent methods for NSData, NSDictionary and NSArray. For NSStrings, this method is equivalent to calling `writeToFile:atomically:encoding:error:` with the UTF8 encoding. For any other object it will attempt to serialise using the NSCoding protocol and write out the file as a NSCoded binary plist archive. If the object does not implement the NSCoding protocol, an exception will be thrown.


Classes
--------------

There is a single class, BaseModel which you should use as the base class for any model-type classes. BaseModel provides a core set of functions for dealing with model data, and through the BaseModel protocol, provides hooks to implement additional bespoke behaviours with minimal coding.


Optional methods
--------------

The BaseModel class implements the BaseModel protocol, which specifies some optional methods that can be implemented by BaseModel subclasses to extend the functionality. The BaseModel protocol defines the following optional methods:

	- (void)setUp;
	
BaseModel's initialisation routine is quite complex, and it is not advised that you attempt to override any of the constructor methods (there is no 'designated initializer'). Instead, to perform initialisation logic, implement the setUp method. This is called after the class has been successfully initialised, so there is no need to verify that self is not nil or call `[super setUp]` (although it is safe to do so). Like `init`, `setUp` is called only once at the start of the lifetime of an instance, so it is safe to set properties without releasing their existing values. You should never call `setUp` yourself directly, except in the context of `[super setUp]`.

	- (id)setWithDictionary:(NSDictionary *)dict;
	- (id)setWithArray:(NSArray *)array;

These methods are used to extend you model with the capability to be initialised from an array or dictionary. This is useful as it allows objects to be automatically loaded from a plist in your application bundle. It could also be used to instantiate objects from other formats like JSON or XML via an intermediate library like TouchJSON or XMLDictionary. These methods are called after the `setUp` method, so you should not assume that class properties and ivars do not already have values at the point when this method is called. Be careful to safely release any property values before setting them. 

	- (void)setWithCoder:(NSCoder *)aDecoder;
	
This method is called by `initWithCoder:` as part of the NSCoding implementation. If you are implementing NSCoding serialisation for your class, you should implement this method instead of overriding `initWithCoder:`. This method is called after the `setUp` method, so you should not assume that class properties and ivars do not already have values at the point when this method is called. Be careful to safely release any property values before setting them.


Properties
--------------

The BaseModel class has the following instance properties:

	@property (nonatomic, retain) NSString *uniqueID;
	
This property is used to store a unique identifier for a given BaseModel instance. The uniqueID getter method is actually a lazy constructor that uses the CFUUID APIs to create a globally unique ID the first time it is called for each model instance, so you should normally not need to set this property unless you need to override the ID for a specific object. Note however that responsibility for loading, saving and copying this ID is left to the developer. If you do not preserve this value when saving and loading your model then it will be different each time the object is re-instantiated.


Methods
---------------

The BaseModel class has the following methods:

	+ (id)instance;
	- (id)init;
	
Create an autoreleased instance or initialises an alloc'ed instance of the class respectively. This will attempt to initialise the class from `resourceFile` if that file exists, otherwise it will just call setUp.
	
	+ (id)instanceWithDictionary:(NSDictionary *)dict;
	- (id)initWithDictionary:(NSDictionary *)dict;
	
Creates/initialises an instance of the class and initialise it using a dictionary. This is useful when loading a model from an embedded Plist file in the application bundle, or creating model objects from JSON data returned by a web service. This method requires the `setWithDictionary:` method to be defined on your subclass. This method will attempt to initialise the class from `resourceFile` (if that file exists) prior to calling `setWithDictionary:`.
	
	+ (id)instanceWithArray:(NSArray *)array;
	- (id)initWithArray:(NSArray *)array;
	
As above, except the model object is initialised with an array. Useful if your Plist or JSON file does not use a dictionary as the root object. This method requires the `setWithArray:` method to be defined on your subclass. This method will attempt to initialise the class from `resourceFile` (if that file exists) prior to calling `setWithDictionary:`.

	+ (id)instanceWithContentsOfFile:(NSString *)filePath;
	- (id)initWithContentsOfFile:(NSString *)filePath;
	
Creates/initialises an instance of the model class from a file. If the file is a plist representing NSArray or NSDictionary objects then the model will be initialised using the `initWithArray` or `initWithDict` methods. If the file is an NSCoded archive of an instance of the model then the object will be initialised using `initWithCoder`. If the file format is not recognised, or the appropriate init function is not implemented, the method will return nil. If only a filename or partial path is provided, the app will look first in the application support folder and then in the application bundle resources.

	+ (id)sharedInstance;

This returns a shared instance of the model object, so any BaseModel subclass can easily be used as a singleton via this method. The shared instance is created lazily the first time it is called, so this functionality has no overhead until it is used. The shared instance is created by first calling `setUp` and then attempting to load first the file specified by the `resourceFile` method and then the file specified by`saveFile`.

	+ (BOOL)hasSharedInstance;
	
Because `sharedInstance` is a lazy constructor, you cannot call it to test if a given class has a shared instance or not. The `hasSharedInstance` lets you check whether a given model has a shared instance without accidentally creating one.

	+ (void)setSharedInstance:(BaseModel *)instance;

This method lets you replace the current shared model instance with another instance of the model. This is useful for mutable models that may be re-loaded from a file or downloaded from a web service. The previous shared instance will be autoreleased when the new one is set. Note that since the shared model instance is replaced, any objects hanging on to references to the model will need to be updated. The model broadcasts a `BaseModelSharedInstanceUpdatedNotification` via NSNotificationCenter whenever this method is called, so setting an observer for that event is a good way to make sure that any references are kept up to date.

	+ (void)reloadSharedInstance;

This method reloads the shared instance of the model using the file specified by `saveFile`. This method replaces the sharedInstance by calling `setSharedInstance:` internally, so the same notes apply regarding updating references.

	+ (NSString *)resourceFile;

This method returns the filename for a file to be used to initialise every instance of the object. This would typically be a plist file stored in the application bundle, and is a fantastic way to quickly define complex default data sets for model objects. This can be a full or partial path name. Partial paths will be treated as relative to the application bundle resources folder. The default return value for this method is the *ClassName.plist* where ClassName is the name of the model class, but you can override this method in your own subclasses to change the file name.

In case you are wondering, there is a small overhead to loading this file the first time you create an instance of your model, however the file is cached and re-used for subsequently created model instances where possible. For models that have no initialisation file, just make sure that no file called ClassName.plist exists in the bundle, and no initialisation will take place. It is not necessary to override this method and return nil, unless you need to have a resource file called ClassName.plist that isn't being used for this purpose.

	+ (NSString *)saveFile;

This method returns a filename for a file to be used to load and save the shared (singleton) instance of the class. As with the resourceFile, this can be a full or partial path name. Partial paths will be treated as relative to Library/Application Support/ on iOS or Library/Application Support/AppName/ on Mac OS. By default the name of this file is ClassName.plist, but you can override this method in your own subclasses to change the file name.

	- (void)save;

This method checks to see if the instance being saved is the shared (singleton) instance. If so, it will save to the file specified by the `saveFile` method by using the NSCoding protocol and calling `encodeWithCoder:`. If the instance is not the shared instance it will throw an exception. You can override the save method in your subclasses to provide an implementation for saving individual models. A typical approach might be to use the `uniqueID` property to generate a unique file name for each instance and then save the object using the `writeToFile:atomically:` method. Note that if you are using this approach you will need to save and load the uniqueID property or the class will be saved with a different file name each time (leading to a proliferation of files).


Usage
-----------

The BaseModel class is abstract, and is not designed to be used directly. To implement a model object, create a new subclass of the BaseModel class and implement or override the methods that need to be customised for your specific requirements. Look at the TodoList project for an example of how to do this.