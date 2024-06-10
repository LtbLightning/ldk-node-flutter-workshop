# Prerequisites

This workshop is a hands-on workshop for software developers. To be able to participate, you need to have some [Software and Tools](#software-and-tools) installed.

On average it takes about 60 to 90 minutes to install everything, so please plan accordingly.

If you encounter any issues or have any questions, please reach out on Let there be Lightning's [Discord community](https://discord.gg/Q7utrQ5Sz7).

> [!IMPORTANT]
> If you attend an instructor-led session, there will not be any time to do this during the workshop, so please make sure to have everything installed and ready to go **before** the start of the workshop.

## Software and Tools

### Git

Since we will be using git to clone the workshop repository to have the same starting point, make sure you have git installed on your system.

It is very probable that you already have it installed, but if you don't, you can check by running `git --version` in a terminal. If it is installed a version number will be returned, if not, you will see an error message.

If you don't get a version returned, you can follow the instructions from [git-scm](https://git-scm.com/downloads) or [github](https://github.com/git-guides/install-git) to install it.

### Flutter

The mobile development framework used will be Flutter, as to easily build applications for both Android and iOS and to make use of existing Bitcoin and Lightning libraries.

Following the [official installation instructions](https://flutter.dev/docs/get-started/install), install Flutter for your operating system.

> [!CAUTION]  
> It is important to select iOS or Android when choosing your first type of app. Do **NOT** select Desktop or Web!

The app will be developed to run on both Android and iOS, so if you would like to run the app on both Android and iOS, you will need to install Flutter for both app types. To just run the app during the workshop, it is sufficient to follow the instructions for just one of the two.

Make sure that running `flutter doctor` in a terminal shows no errors, as described in the installation instructions.

### IDE or code editor

The instructor of the workshops will be using [VSCodium](https://vscodium.com/), a free and opensource distribution of [Visual Studio Code](https://code.visualstudio.com/) without Microsoft's telemetry/tracking, so it might be easier to follow along if you use it too, but any IDE or code editor should work.

If you install VSCodium, make sure to also install the [Flutter extension](https://open-vsx.org/extension/Dart-Code/flutter) and [Dart extension](https://open-vsx.org/extension/Dart-Code/dart-code).
