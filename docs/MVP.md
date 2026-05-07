# Signotes MVP and Roadmap

## Product Goal

Signotes is an open source iPad notes app for students and developers who want a free, local-first handwriting workflow with Apple Pencil. The core experience is organized folders, lessons, A4 pages, paper templates, and a fountain pen tool.

## MVP Scope

The MVP should prove the writing experience and note organization without introducing sync, accounts, or a custom drawing engine.

### Included

- Native iPadOS app built with SwiftUI.
- Apple Pencil writing through PencilKit.
- Fountain pen preset based on `PKInkingTool.InkType.fountainPen`.
- Tool presets for fountain pen, pen, pencil, marker, and eraser.
- Local folder/note/page model.
- A4 page surface with fixed aspect ratio.
- Paper templates:
  - blank
  - ruled
  - grid
  - dotted
- Local autosave of `PKDrawing` data.
- Basic page navigation.
- Initial seed folder: `Matematica`, with `Lezione 1`.

### Not Included Yet

- iCloud sync.
- Account system.
- Collaboration.
- OCR/search inside handwriting.
- PDF import/annotation.
- PDF export polishing.
- Custom proprietary renderer.
- Android or cross-platform version.

## Architecture

Name: **Modular Clean Architecture with MVVM Presentation**.

Layers:

- `Domain`: pure app concepts such as folders, notes, pages, templates, tools, repository protocols, and use cases.
- `Data`: filesystem repository, JSON metadata, and serialized PencilKit drawings.
- `Presentation`: SwiftUI screens and view models.
- `Presentation/Canvas`: UIKit/PencilKit bridge wrapped for SwiftUI.
- `App`: dependency composition.

This lets the app start simple while keeping future replacement points clear. For example, the PencilKit canvas can later be replaced or complemented by a custom renderer without rewriting folder management, persistence, or editor state.

## Persistence Model

Initial local format:

- `library.json`: folder/note/page metadata.
- `drawings/<page-id>.drawing`: serialized `PKDrawing`.

Future open format:

- versioned manifest
- page metadata
- paper template metadata
- vector stroke data
- optional PDF export cache

## Fountain Pen Strategy

### MVP

Use PencilKit's native fountain pen:

```swift
PKInkingTool(.fountainPen, color: .black, width: 2.4)
```

This gives a native, low-latency calligraphic/fountain-pen-like stroke without building a drawing engine.

### Future Custom Renderer

A proprietary renderer is a separate project track and should not block the MVP.

Possible roadmap:

1. Capture raw Apple Pencil points, pressure, altitude, azimuth, timestamp, and predicted touches.
2. Smooth the input path while keeping latency low.
3. Convert points into a variable-width stroke mesh.
4. Model nib angle and pressure response.
5. Render with Metal for performance.
6. Store strokes in a versioned vector format.
7. Implement eraser, lasso selection, undo/redo, PDF export, and hit-testing.

Difficulty estimate:

- Basic custom line: 4/10.
- Usable fountain pen: 7/10.
- Goodnotes-level feel: 9/10.

## Suggested Milestones

### Milestone 1: Native Writing Prototype

- App opens on iPad.
- One seeded note.
- A4 page with grid background.
- PencilKit canvas works with fountain pen.
- Drawing persists locally.

### Milestone 2: Notes Library

- Create folders.
- Create notes.
- Add pages.
- Switch between pages.

### Milestone 3: Paper and Tools

- Template picker.
- Saved tool presets.
- Color and width controls.
- Better page zoom/pan.

### Milestone 4: Export and Interop

- Export note as PDF.
- Import PDF as page background.
- Share `.signotes` package.

### Milestone 5: Advanced Engine Track

- Experimental custom renderer behind a feature flag.
- Side-by-side comparison with PencilKit.
- Keep PencilKit as stable default until the custom renderer is clearly better.

