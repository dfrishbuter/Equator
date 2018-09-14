<p align="center">
  <img src="img/equator.png" width="600" alt="Equator"/>
</p>

![Swift4](https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat")
![Platform](https://img.shields.io/badge/Platform-Mac%20OS-lightgrey.svg)
![License](https://img.shields.io/packagist/l/doctrine/orm.svg)

**Equator** is useful extension for XCode IDE. This tool has a really simple mechanism, that allows to generate fully implemented `Equatable` protocol extensions for swift objects just in two clicks.

# Installation 🎬

1. Download and extract `.zip` file containing latest release from the releases tab of the repo
2. Drag `Equator.app` to your Applications folder and run the app
3. Go to `System Preferences` -> `Extensions` -> `Xcode Source Editor` and enable the extension
4. Restart the XCode

# Usage 🏄‍♂️

Select all lines of target class/struct/enum body.

```swift
struct User {            <- Start of selection
    public var name: String
    public var id: Int
}                            <- End of selection
```

Go to `Editor` -> `Equator` -> `Generate Swift Equatable` and you'll achieve:

```swift
extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name &&
               lhs.id == rhs.id
    }
}
```

# Author ✍️

Dmitry Frishbuter, dmitry.frishbuter@gmail.com

# License 📃

**Equator** is available under the MIT license. See the LICENSE file for more info.
