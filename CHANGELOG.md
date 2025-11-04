### 1.0.0 - Initial Release & Decoupling for Future Development
This marks the initial official release (v1.0.0) of neom_downloads as a new, independent module within the Open Neom ecosystem. Previously, download functionalities were often integrated directly into broader modules like neom_commons or scattered across the main application. This decoupling is a crucial step in formalizing the download management layer, enhancing modularity, and strengthening Open Neom's adherence to Clean Architecture principles.

Key Highlights of this Release:

New Module Introduction & Specialization:

neom_downloads is now a dedicated module for all media download processes, ensuring a clear separation of concerns from other common utilities or media-related functionalities.

This allows for specialized development and maintenance of download-specific features.

Decoupling from neom_commons (and other modules):

Download management logic and UI components have been entirely extracted and centralized into this module. This ensures that neom_commons remains focused on generic utilities and that download responsibilities are clearly defined.

Foundational Download Capabilities:

Provides initial functionalities for downloading media items, including:

Requesting and managing necessary storage permissions.

Handling file storage paths across different platforms.

Tracking download progress.

Basic handling for existing files.

Module-Specific Constants & Translations:

Introduced DownloadTranslationConstants for all UI text strings specific to download functionalities, improving localization and maintainability.

Defined DownloadConstants for module-specific configurations (e.g., regex for filenames).

Future-Oriented Development:

This initial release lays the groundwork for significant future expansion. The module is designed to grow with advanced features such as comprehensive offline media management, robust metadata tagging, and more sophisticated download queues.

Leverages Core Open Neom Modules:

Built upon neom_core for foundational services (like DownloadService interface) and neom_commons for reusable UI components and utilities, ensuring seamless integration within the ecosystem.