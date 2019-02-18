# ImmutableSwift

ImmutableSwift is a tool that generates swift model that supports immutability, coding(Coding and NSCoding), value comparions, hashing and copying. Directly inspired by [facebook/remodel](https://github.com/facebook/remodel).

TLDR: generate this
```
import Foundation

class Friend : Hashable, Codable, NSCopying{
	let name : String
	let daySinceFirstMet : Int

	init(name:String, daySinceFirstMet:Int) {
		self.name = name
		self.daySinceFirstMet = daySinceFirstMet
	}

	static func == (lhs: Friend, rhs: Friend) -> Bool {
		return lhs.name == rhs.name && lhs.daySinceFirstMet == rhs.daySinceFirstMet
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(daySinceFirstMet)
	}

	func copy(with zone: NSZone? = nil) -> Any {
		let copy = Friend(name:name,daySinceFirstMet:daySinceFirstMet)
		 return copy
	}
}
```
from this
```
Friend {
    String name
    Int daySinceFirstMet
}
```

## Download
You can download the latest release from here: https://github.com/hackthehackerman/ImmutableSwift/releases

## Build
```sh
$ git clone git@github.com:hackthehackerman/ImmutableSwift.git
$ cd ImmutableSwift
$ swift build -c release
```

## Usage
To generate a model, you must first create a `.value` file that contains the modle schema. Here is an example:
```
Friend {
    String name
    Int daySinceFirstMet
}
```

Once you created the schema file, you can generate the desired swift model with
```
./ImmutableSwift Path/To/ModelDirectory/Friend.value
```

To generate models for every .value files in a directory, subtitute the file path with a directory path
```
# this will also generate every .value files in any sub-directories recursively
./ImmutableSwift Path/To/ModelDirectory/
```

## Import
ImmutableSwift assumes that every types that a model depends on reside in the same module. If a model depends on another module, simply add the required module on top of the schema. For example:
```
import PhoneNumber
Friend {
    String name
    Int daySinceFirstMet
    PhoneNumber number
}
```
The syntax for import are the same as swift's import syntax. You can import a module with `import module`, import a submodule with `improt module.submodule` or import a specific kind of symbol with `import kind module.symbole`

## Comments
ImmutableSwift supports adding comments to the generated models. 
```
import PhoneNumber
Friend {
    # example comment
    String name
    # at the moment, ImmutableSwift only support comments inside the model bracket (between brackets)
    Int daySinceFirstMet
    # comment must be in its own line, and starts with a pound sign #
    PhoneNumber number
}
```

## AccessControl
ImmutableSwift supports defining optional access levels for the generated model. At the moment, it only supports `public` and `internal`. This is mainly to help generate models in a module that are meant to be imported. For example:
```
public Friend {
    String name
    Int daySinceFirstMet
}
```

## NSCoding
In some projects, immutable data model might need to support NSCoding. To have ImmutableSwift generates associated methods that support NSCoding, include the plugin `ISCoding` in the model's schema.
```
# here, ISCoding plugin is responsible for generating the encode and init method required by NSCoding protocol
# ISCopying plugin is responsible for generating the copy method required by the NSCopying protocol
public Friend (ISCoding, ISCopying){
    String name
    Int daySinceFirstMet
}
```

## Plugins
Similar to [facebook/remodel](https://github.com/facebook/remodel), ImmutableSwift uses a simple plugin system. The plugin system are designed to encapsulate cohesive generation logics, and extend the functionality of the code generator. You can find a list of plugins here: https://github.com/hackthehackerman/ImmutableSwift/tree/master/Sources/ImmutableSwift/generating/plugins.

To specify plugins for a specific model, add the list after the model name. Noted that, if you don't specific a list of plugins to used, ImmutableSwift will use a default list of plugins: [ISCodable, ISHashable, ISCopying].
```
# ISCodable is responsible for generating codes for the Codable protocol
# ISHashable is responsible for generating the == and hash function for the Hashable protocol
# ISCopying plugin is responsible for generating the copy method required by the NSCopying protocol
public Friend (ISCodable, ISHashable, ISCopying){
    String name
    Int daySinceFirstMet
}
```

## Contributing
Pull requests are very welcomed! 
