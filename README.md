# ios-marvel-app
### Description
Demo app used as challenge for iOS development position.
The app uses Marvel API to fetch characters so it can populate a character list with some informations, like names, descriptions and thumbnails.

### Images
![Splash](https://imgur.com/BeoJX79)
![CharacterList](https://imgur.com/D5zCehE)
![DetailsScreen](https://imgur.com/gLCysf1)

### Used build, take it as a guide for the requirements
- XCode 12.0.1
- Swift 5
- Marvel API (https://developer.marvel.com)
- CocoaPods:
  - Alamofire ~> 5.2 (https://cocoapods.org/pods/Alamofire)
  - AlamofireImage ~> 1.0 (https://cocoapods.org/pods/AlamofireImage)
  - CryptoSwift ~> 4.1 (https://github.com/krzyzanowskim/CryptoSwift)

### Used runtime target 
- iOS 14.0

### Building the app
Because this is a small project, the podfiles were pushed to the git repository as the size of the libraries weren't too much.
This is to facilitate, so there is no need to install cocoapods in your system and the libraries in the project as they are already there.
Now you only need a few steps:
- Clone the repository and open the project by the MarvelHeroes.xcworkspace file 
- Get both your public and private api keys in your developer account located in https://developer.marvel.com/ (there is a "Get a Key" button there)
 - Inside the project, look for the apikeys.plist file in the project navigator
 - Add the public and private keys in their specific locations
 - In the same page where your keys are located, scroll down and add another authorized referrer: "gateway.marvel.com" as it's being used by the project

#### Guides
Thank you for the provided material used during the development, such as official documentation, tutorials, projects repositories and ideas for the app design.

#official documentation#
https://developer.marvel.com/documentation/entity_types
https://developer.marvel.com/documentation/apiresults
https://developer.marvel.com/documentation/authorization
https://developer.marvel.com/docs

#project repositories#
https://github.com/asfourco/marvel-api-ios-app
https://github.com/ciceroduarte/MarvelCharacters
https://github.com/pamnovalli/marvel-app-ios
https://github.com/soujohnreis/marvel-catalog-ios
https://github.com/AnasAlhasani/Marvel
https://github.com/micheltlutz/marvelapp

#article#
https://www.raywenderlich.com/6587213-alamofire-5-tutorial-for-ios-getting-started#toc-anchor-005