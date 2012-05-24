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