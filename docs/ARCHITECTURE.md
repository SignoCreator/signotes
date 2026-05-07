# Architecture

Name: **Modular Clean Architecture with MVVM Presentation**.

## Layers

- `App`: app entry point and dependency composition.
- `Domain`: pure business models, repository protocols, and use cases.
- `Data`: persistence and external adapters.
- `Presentation`: SwiftUI screens, view models, and UIKit bridges.
- `Shared`: cross-cutting utilities that are not tied to a single layer.

## Initial Boundaries

The MVP should keep the note library, page metadata, and drawing persistence behind domain-level protocols. PencilKit should live behind the `Presentation/Canvas` boundary at first, so a future custom renderer can be introduced without rewriting library management.

## Future Renderer Boundary

The custom renderer should be treated as an engine module with its own stroke model, input pipeline, and rendering backend. It should not leak directly into folder, note, or page management.

