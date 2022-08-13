<p align="center">
  <img src="Resources/Icon Transparent.png" alt="Icon" width=512 />
</p>

# Recon Bolt

This is a companion app for Valorant. It started as a way to view your competitive rank changes (back before the numbers were visible) and has now evolved into so much more, even allowing you to participate in agent select from anywhere. Check out the screenshots for a clearer overview than I could ever give in words!

Unfortunately, this app needs your Riot username and password to function, but of course you can view the code yourself to check its safety, and the password is stored in the keychain rather than as plaintext.

## Discord

I've created a Discord server for this app! Feel free to [join the server](https://discord.gg/bwENMNRqNa) if you'd like to discuss it :)

## Download (TestFlight)

I've uploaded a build of the app to Apple and they approved it for beta testing! [Here's the link](https://testflight.apple.com/join/M1e2dgxj) to join the beta.

Please note that the app currently **only supports iOS 15+**, but you should be on the latest version of iOS anyway—iOS 15 supports all the same devices as iOS 14 and iOS 13 did.

## Screenshots

(Some of this data is mocked, some is real—*can you tell which is which?*)

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/profile.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/profile.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/summary.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/summary.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/party.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/party.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/missions.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/missions.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/loadout.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/loadout.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/skin.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/skin.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/store.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/store.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/agent select.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/agent select.png" />
</p>

<p align=center>
  <img width="49%" src="Resources/GitHub/Screenshots/Light/agent info.png" />
  <img width="49%" src="Resources/GitHub/Screenshots/Dark/agent info.png" />
</p>


## Thanks

This project would not have been possible (or was significantly eased by) some prior work:

- **[RumbleMike/ValorantStreamOverlay](https://github.com/RumbleMike/ValorantStreamOverlay)** provided the initial inspiration (and even just let me know it was possible).
- **[RumbleMike/ValorantClientAPI](https://github.com/RumbleMike/ValorantClientAPI) and the associated Discord**: This has some nice docs and a great community for working with the API I need.
- **[colinhartigan/valclient.py](https://github.com/colinhartigan/valclient.py)** has filled in where the above docs were incomplete, providing a simple reference of what endpoints exist and how they're accessed.
- **[techchrism/valorant-api-docs](https://github.com/techchrism/valorant-api-docs)** is another documentation effort that I was recently made aware of, which looks both complete and detailed!
- **[Valorant-API.com](https://valorant-api.com)** has proven to be a truly invaluable API, serving up the game's assets in an easy-to-use format. They were also wonderfully open and responsive to feature/change requests.

## Why not Android?

The vast majority of Recon Bolt is UI Code, which heavily relies on Apple's fantastic new SwiftUI framework. I simply would not have had the motivation to work this much on an app with any other framework I know of, much less for an OS which I don't even use. Sorry!
