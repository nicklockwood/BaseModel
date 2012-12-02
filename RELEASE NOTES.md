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