[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![Dart](https://github.com/emdgroup/flutter_identity/actions/workflows/dart.yml/badge.svg)](https://github.com/emdgroup/flutter_identity/actions/workflows/dart.yml)

# Flutter Identity

<p float="left">
<img src="./screenshot.PNG" width="150" />
<img src="./login_dialog.PNG" width="150" />
<img src="./login_form.PNG" width="150" />
<img src="./screenshot_desktop.png" width="300" />
</p>
Example implementation of the identity platform in Flutter.

## Getting Started

For help getting started with Flutter, view the
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Please refer to the guide in the identity docs

[https://docs.emddigital.com/identity/flutter](https://docs.emddigital.com/identity/flutter)

## Credential storage

This example implementation stores the tokens using `flutter_secure_storage` package. This persists to iOS Keychain and Secured preferences. Follow the instructions [here](https://pub.dev/packages/flutter_secure_storage) to enable the right permissions for your application targets.

## Desktop authentication

Since `flutter_appauth` currently does not support running on desktop platforms there's an implementation of authorization with PKCE in the `lib/src/services/desktop` folder.

## Web authentication

Since `flutter_appauth` currently does not support running on web platforms there's an implementation of authorization with PKCE in the `lib/src/services/web` folder.

### Authentication steps on desktop:

- Discovery URL is called to fetch the authorization endpoint for oAuth.
- A check if the server supports the S256 code challenge method is performed. Authentication will fail if the server does not include S256 in the response to the discovery request (`code_challenge_method`)
- A challenge is generated using secure crypto randoms and hashed using SHA256. The has is included as Base64URl string to the server.
- The app launches a browser window for authenticating the user. Included in the url is the redirect url for the local loopback server that will process the authentication code
- The server is started once the browser was opened.
- Once the authentication flow is completed the user is redirected to the local server, with the authentication code as a query parameter.
- The app requests the tokens with the authentication code and raw challenge to verify the request

ℹ️ The default port for the local loopback server is 8080

ℹ️ The url will be opened using the `url_launcher` package. This opens the default browser of the platform by default.
