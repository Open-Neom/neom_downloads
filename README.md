# neom_downloads
neom_downloads is a specialized module within the Open Neom ecosystem, dedicated to providing
robust media download functionalities. It enables users to download various types of media items
(e.g., audio, video, documents) for offline access, ensuring a seamless content consumption experience
regardless of internet connectivity. 

This module handles the entire download process, from requesting necessary permissions
and managing file storage to tracking download progress and updating media metadata.
Designed for reliability and user convenience, neom_downloads aligns with the Tecnozenism
philosophy of empowering users with greater control over their digital content.
It strictly adheres to Open Neom's Clean Architecture principles, ensuring its logic is robust,
testable, and decoupled from direct UI presentation. It seamlessly integrates with neom_core
for core services and data models, and neom_commons for shared UI components,
providing a cohesive download experience.

🌟 Features & Responsibilities
neom_downloads provides a comprehensive set of functionalities for media downloads:
•	Media Download: Supports downloading single media items (DownloadButton) or 
    multiple items (e.g., a playlist via MultiDownloadButton).
•	Permission Management: Handles requesting and verifying necessary storage permissions
    (e.g., Permission.storage, Permission.manageExternalStorage) across different
    platforms (Android, iOS, desktop).
•	File Storage Management: Determines and manages appropriate download paths for various
    operating systems, including creating custom subfolders.
•	Download Progress Tracking: Provides real-time progress updates for ongoing downloads,
    allowing users to monitor the status.
•	Duplicate File Handling: Offers options for handling existing files
    (e.g., skip, replace, rename with increment).
•	Metadata Tagging (Future): Includes hooks for adding metadata (e.g., title, artist, album, cover art)
    to downloaded audio files (currently implemented for Android, with future plans for iOS).
•	Offline Access: Stores downloaded media items in Hive for quick retrieval and offline playback.
•	User Preferences Integration: Integrates with user preferences for download quality, format,
    and filename conventions (managed via DownloadTranslationConstants for keys).
•	Error Handling: Implements robust error handling for download failures, providing user feedback.

🛠 Technical Highlights / Why it Matters (for developers)
For developers, neom_downloads serves as an excellent case study for:
•	Platform-Specific File System Interaction: Demonstrates how to interact with native file systems
    and storage directories (path_provider, permission_handler) across different operating systems.
•	Asynchronous Network Operations: Manages complex, long-running download tasks using http client
    and streams, with progress notification.
•	ChangeNotifier & GetX Integration: Utilizes ChangeNotifier (within DownloadController) for granular
    UI updates during download progress, and integrates with GetX for dependency injection and controller lifecycle.
•	Permission Handling: Provides robust examples of requesting and managing various storage-related permissions.
•	Data Persistence (Hive): Demonstrates using Hive for fast, local storage of download metadata and tracking downloaded items.
•	Service-Oriented Architecture: It is designed to implement a DownloadService interface (defined in neom_core),
    showcasing how download functionalities are exposed through an abstraction, allowing other modules
    to trigger downloads without direct coupling.
•	Error Recovery: Includes logic for retrying file creation after permission issues.

How it Supports the Open Neom Initiative
neom_downloads is vital to the Open Neom ecosystem and the broader Tecnozenism vision by:
•	Empowering Offline Content Access: Allows users to access essential media (e.g., guided meditations,
    educational content, music) without an internet connection, enhancing accessibility and convenience.
•	Enhancing User Control: Provides users with greater control over their digital content,
    aligning with the Tecnozenism principle of conscious interaction with technology.
•	Supporting Diverse Content Consumption: Facilitates the consumption of various media types,
    enriching the overall platform experience.
•	Driving Engagement: Offline capabilities can significantly boost user engagement,
    especially in areas with limited connectivity.
•	Showcasing Modularity: As a specialized, self-contained module for a core utility,
    it exemplifies Open Neom's "Plug-and-Play" architecture, demonstrating how complex
    functionalities can be built independently and integrated seamlessly.

🚀 Usage
This module provides DownloadButton for single item downloads and MultiDownloadButton for batch downloads.
Its DownloadController implements DownloadService (from neom_core), allowing other modules 
(e.g., neom_itemlists, neom_media_player) to trigger and manage download operations via the service interface.

📦 Dependencies
neom_downloads relies on neom_core for core services, models, and routing constants, and on neom_commons 
for reusable UI components, themes, and utility functions. It directly depends on path_provider,
permission_handler, http, and hive for its core functionalities.

🤝 Contributing
We welcome contributions to the neom_downloads module! If you're passionate about file management,
network operations, offline capabilities, or enhancing the user's control over their content,
your contributions can significantly strengthen Open Neom's utility.

To understand the broader architectural context of Open Neom and how neom_downloads fits into
the overall vision of Tecnozenismo, please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning
and engagement possible within the project, consult our comprehensive guide: Learning Flutter
Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
