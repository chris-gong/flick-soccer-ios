# Flick Soccer
### What is Flick Soccer
Flick Soccer is a remake of the popular mobile game, Flick Shoot, made using Swift and SceneKit. Our version only has one game mode, scoring against an AI that gets progressively harder as you score more goals. Currently, the ball is kicked by swiping the ball once to get it off the ground and the ball is curved by swiping the ball again after lift off. If you're interested in how the game was made, then I'd highly encourage you to check out our [youtube channel](https://youtu.be/kjEC1U_MmPg).

![Imgur1](https://i.imgur.com/kkyrJ04m.png)
![Imgur2](https://i.imgur.com/CkJ9nUPm.png)
![Imgur3](https://i.imgur.com/sSd6HkQm.png)

### How to build and run Flick Soccer
In order to build and run the app, download the project and unzip the download file. Then, open the file called "FlickSoccer.xcodeproj" in Xcode. Proceed to the same file at the very top of the Project Navigator and make sure it is selected (the blue file icon). Now, make sure the "General" tab is selected at the top middle. Under the section titled "Identity", change the value of the textbox to the right of where it says "Bundle Identifier". After that, under the section titled "Signing", change the value of the dropdown to the right of where it says "Team" with an account associated with your Apple ID. The reason for this is so that you can run the game on your device. The simulator is just not suited for testing apps made in SceneKit.
