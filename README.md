# WOLMonitoring 

![Xcode Version](https://img.shields.io/badge/Xcode-26.0.1-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

A native iOS application for managing and monitoring your computers and servers connected to the devices network.

<img width="426" height="862" alt="Screenshot 2025-09-25 at 01 40 50" src="https://github.com/user-attachments/assets/3d97758c-7675-4e22-ae58-183aaea8380c" />

## About The Project

WOLMonitorin was created to provide a simple, clean, and powerful interface for managing your personal computers, home servers, or work machines directly from your phone. This app keeps all your machine information organized and accessible, with powerful network tools planned for the future.

Built entirely with SwiftUI, the app is designed to be fast and easy to use while being descriptive and useful.

### Built With

* [Swift](https://developer.apple.com/swift/)
* [SwiftUI](https://developer.apple.com/xcode/swiftui/)
* [Google Gemini AI](https://gemini.google.com/app/)

## Features

### Current-ish Features
* **Device Management:** Easily add, edit (kinda), and delete computers from your list.
* **Detailed Information:** Store essential details for each machine, including a nickname, MAC address, and (soon) custom notes.
* **Local Persistence:** Your device list is securely saved on your device.

### Upcoming Features
*  **Wake-On-LAN (WOL):** Power on your computers remotely from anywhere with an internet connection (may require a remote VPN and separate host machine).
*  **Remote Sensor Reading:** Monitor hardware stats like CPU temperature, fan speeds, and memory usage (will require a companion agent on the host machine).
*  **Live Status Pinging:** See at a glance which machines on your network are online or offline.
*  **Notifications:** Recieve notifications regarding your machines such as new power status, high temperatures, and more.
*  **iCloud Sync:** Keep your computer list synchronized across all your Apple devices (iPhone, iPad, Mac).

## Getting Started

To get a local copy up and running, build this repository in Xcode 26.0 or greater.

### Prerequisites

* macOS 26 running the latest version of Xcode

### Installation

1.  Clone the repo
    ```sh
    git clone https://github.com/)rngkGit/WOLMonitoring.git
    ```
2.  Open the project in Xcode
3.  Build and run the project using the Xcode simulator or by deploying to a physical device.

## Usage

### Adding / Removing Machienes

1.  Launch the app on your iPhone.
2.  Tap the `+` button at the bottom to add a new computer.
3.  Fill in the details for your machine, such as the name and MAC address.
4.  Tap "Save".
5.  Your machine will now appear in the main list. Tap on it to view its details. Editing details coming soon.

## Roadmap

See the [open issues](https://github.com/rngkGit/WOLMonitoring/issues) for a full list of proposed features (and known issues).

- [X] **Core:** Add, Edit, and Delete Computer Profiles
- [ ] **Feature:** Implement Wake-On-LAN (WOL) Packet Sending
- [ ] **Feature:** Implement ICMP Ping for Live Status Checks
- [ ] **Feature:** Notifications
- [ ] **Enhancement:** iCloud Sync Integration
- [X] **Feature:** Companion Agent for Sensor Reading (CPU Temp only right now)
- [ ] **Feature:** API for receiving sensor data in the iOS app

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement" or similar.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## Final Note

Thanks to everyone who has used my application(s)! I greatly appretiate you. See you on my next project!

\- rngk

## License

Distributed under the MIT License. See `LICENSE.md` for more information.
