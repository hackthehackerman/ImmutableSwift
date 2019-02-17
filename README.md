# ImmutableSwift

ImmutableSwift is a tool that generates swift model that supports immutability, coding(Coding and NSCoding), value comparions, hashing and copying. Directly inspired by [facebook/remodel](https://github.com/facebook/remodel).

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

