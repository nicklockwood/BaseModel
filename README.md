Purpose
--------------

BaseModel provides a base class for building model objects for your iOS or Mac OS projects. It saves you the hassle of writing boilerplate code, and encourages good practices by reducing the incentive to cut corners in your model implementation.

The BaseModel object uses the NSCoding protocol for serialisation. It is not designed for use with Core Data, although in principle the class could easily be extended to work with Core Data if needed.


Installation
--------------

To use the BaseModel class in your project, just drag the class files into your project. It has no dependencies.


Classes
--------------

There is a single class, BaseModel which you should use for any model-type classes. BaseModel provides a core set of functions for dealing with model data, and through the category extensions `Document` and `Singleton`, provides additional functions for loading/saving files and creating singleton instances of your model classes.


Optional methods
--------------

The BaseModel class implements the BaseModel protocol, which specifies some optional methods that can be implemented by BaseModel subclasses to extend the functionality. The BaseModel protocol defines the following optional methods:

	- (void)mergeValuesFromObject:(id)object;
	
This method can be used to add the ability to merge one instance of your object into another. This is useful for file loading where you may wish to merge values from a local saved instance of your model with a set of default data loaded from a plist in the application resources.

	- (id)initWithDict:(NSDictionary *)dict;
	- (id)initWithArray:(NSArray *)array;

These methods are used to extend you model with the capability to be initialised from an array or dictionary. This is useful as it allows objects to be automatically loaded from a plist in your application bundle. It could also be used to instantiate objects from other formats like JSON or XML via an intermediate library like TouchJSON or XMLDictionary.

	+ (NSString *)resourceFile;

This method does nothing unless you override it with your own implementation. It returns the filename to be used by the `sharedInstance` and `reload` methods defined in the BaseModel(Singleton) category. This can be a full or partial path name. Partial paths will be treated as relative to the application bundle resources folder.

	+ (NSString *)saveFile;

This method does nothing unless you override it with your own implementation. It returns the filename to be used by the `sharedInstance`, `reload` and `save` methods defined in the BaseModel(Singleton) category. This can be a full or partial path name. Partial paths will be treated as relative to the application support folder.


Methods
---------------

The BaseModel class has the following methods:

	+ (id)instance;
	
Create an autoreleased instance of the class.
	
	+ (id)instanceWithDict:(NSDictionary *)dict;
	
Create an autoreleased instance of the class and initialise it using a dictionary. This is useful when loading a model from an embedded Plist file in the application bundle, or creating model objects from JSON data returned by a web service. This method requires the `initWithDict:` method to be defined on your subclass.
	
	+ (id)instanceWithArray:(NSArray *)array;
	
As above, except the model object is initialised with an array. Useful if your Plist or JSON file does not use a dictionary as the root object. This method requires the `initWithArray:` method to be defined on your subclass.


The BaseModel(Files) category adds these methods:

	+ (NSString *)cachesFolder;

Returns the application caches folder on iOS, or the user caches folder on Mac OS.  The application bundle name is automatically appended to this folder on Mac OS to avoid namespace issues.

	+ (NSString *)documentsFolder;

Returns the application documents folder on iOS, or the user documents folder on Mac OS. This is to make it simpler to save user files on iOS.

	+ (NSString *)applicationSupportFolder;

Returns the application support folder for the application. This is the recommended place for saving application data files on the respective platforms. The application bundle name is automatically appended to this folder on Mac OS to avoid namespace issues.

	- (BOOL)fileExistsAtPath:(NSString *)filePath;

This checks for the existence of a file (e.g. a saved representation of the model data). It works like the NSFileManager equivalent, except that you can pass it a file name or path fragment instead of a full path and it will automatically check for that file within the application support folder.

	- (void)removeFileAtPath:(NSString *)filePath;

This deletes a file. It works like the NSFileManager equivalent, except that you can pass it a file name or path fragment instead of a full path and it will automatically check for that file within the application support folder.

	- (void)writeObject:(id)object toFile:(NSString *)filePath;

This writes an object to disk. The object will automatically be serialised using an appropriate coding method; dictionaries and arrays are written as Plists, objects that support NSCoding are written as keyed archives. Anything else is written as data. You can pass a file name or path fragment instead of a full path and it will automatically prepend the path for the application file within the application support folder.

	- (id)objectWithContentsofFile:(NSString *)filePath;
	
This will load a file and attempt to de-serialise it as an object. It will correctly decode NSArray and NSDictionary plists, and will unarchive NSCoded files. Any other file will be returned as NSData. File extensions are ignored for the purposes of parsing.

	+ (id)instanceWithContentsOfFile:(NSString *)filePath;
	- (id)initWithContentsOfFile:(NSString *)filePath;
	
Creates a new instance of the model class from a file. If the file is a plist representing NSArray or NSDictionary objects then the model will be initialised using the `initWithArray` or `initWithDict` methods. If the file is an NSCoded archive of an instance of the model then the object will be initialised using `initWithCoder`. If the file format is not recognised, or the appropriate init function is not implemented, the method will return nil. If only a filename or partial path is provided, the app will look first in the application support folder and then in the application bundle resources.

	- (void)writeToFile:(NSString *)filePath;

Attempts to write the file to disk using the NSCoding protocol. You can pass a file name or path fragment instead of a full path and it will automatically prepend the path for the application support folder.


The BaseModel(Singletons) category adds these methods:

	+ (id)sharedInstance;

This returns a shared instance of the model object, so any BaseModel subclass can easily be used as a singleton via this method. The shared instance is created lazily the first time it is called, so this functionality has no overhead until it is used. The shared instance is created by attempting to load first the file specified by the `saveFile` method and then the file specified by `resourceFile`. If neither exists or is defined, the shared object will be created by called alloc/init as usual. If both files exist, and the `mergeValuesFromObject:` method has been implemented, the instance loaded from `saveFile` will be merged into the version loaded from resources.

	+ (void)reload;

This method re-loads the shared object instance using the same search process as for `sharedInstance`. Note that the shared model instance is replaced, so any objects hanging on to references to the model will need to be updated.

	+ (void)save;

This method saves the shared object instance using the specified `saveFile`. If this is not set an exception will be thrown. The object will be saved using the NSCoding protocol.


Usage
-----------

The BaseModel class is abstract, and is not designed to be used directly. To implement a model object, create a new subclass of the BaseModel class and override the methods that need to be customised for your specific requirements. Look at the TodoList project for an example of how to do this.