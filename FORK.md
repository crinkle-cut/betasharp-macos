# BetaSharp Fork Features & Modifications

This document outlines the specific features, bug fixes, and performance optimizations present in this fork (`crinkle-cut/betasharp`) compared to the original upstream repository (`Fazin85/betasharp`).

## 1. Native macOS & Retina (HiDPI) Support

The primary goal of this fork was to make the client fully playable on macOS, specifically addressing issues with high-density (Retina/HiDPI) displays where logical coordinate space does not match physical pixel backing space.

*   **Display Framebuffer Direct Read (`Display.cs`):** Upstream relies on Silk.NET's `_window.FramebufferSize` which on macOS incorrectly reports the *logical* layout size (e.g. 1280x720) instead of the backing pixels (2560x1440). This caused the game to render strictly in the bottom-left quadrant. This fork bypasses Silk.NET to invoke `_glfw.GetFramebufferSize` natively, ensuring `glViewport` occupies the full screen.
*   **Viewport & Mouse Coordinate Matrix Integration:** UI rendering (`glOrtho`) was updated to map logical scaling correctly across physical pixels. `Gui.cs` and `GameRenderer.cs` maintain `Display.getFramebufferWidth/Height()` for viewport projection while maintaining logical sizes for `.guiScale` inputs.
*   **Legacy OpenGL Hardware Support (`VertexArray.cs`):** Preserved conditional logic and `IsSupported` flags for Vertex Array Objects (VAOs) to support legacy OpenGL 2.1 initialization states that macOS occasionally falls back to.

## 2. Rendering Performance Optimizations

Following upstream's `22f02ac` commit ("Abstract Legacy OpenGL & Emulate Fixed-Function Pipeline"), several severe performance bottlenecks were identified and optimized in this fork:

*   **Optimized Transparent Chunk Sorting (`ChunkRenderer.cs`):** 
    *   *Issue:* Translucent chunks were sorting every frame, calculating raw vector distance inside the array sort loop.
    *   *Optimization:* Distances are pre-calculated into an array once per frame, and passed to a highly efficient `Array.Sort` eliminating thousands of `Vector3D` garbage allocations.
*   **Fixed VAO/VBO Handle Leak (`DisplayListCompiler.cs`):**
    *   *Issue:* The new emulated Display List compiler allocated a new `glGenVertexArray` and `glGenBuffer` for *every* draw call (e.g. every UI element, cloud, and star) and abandoned them to the void upon reloading.
    *   *Optimization:* Implemented a pooled memory stack (`_vaoPool`) to recycle OpenGL GPU handles, preventing the game from burning through object IDs and stalling the driver.
*   **Inlined Matrix Translations (`SubChunkRenderer.cs`):**
    *   *Issue:* `Matrix4x4.CreateTranslation(...) * modelViewMatrix` was executing thousands of times per frame, creating massive struct copying overhead.
    *   *Optimization:* Matrix component math for XYZ translation was manually inlined onto the existing view matrix.
*   **Cached VAO Lookups:** Replaced per-frame `VertexArray.IsSupported` property checks with heavily cached boolean fields.

## 3. Emulated OpenGL Hotfixes

*   **Missing IGL Bindings (`IGL.cs`, `EmulatedGL.cs`, `LegacyGL.cs`):** Upstream's Emulated GL pipeline missed definitions for several legacy APIs still active in the codebase. We fully mapped:
    *   `BindAttribLocation(uint, uint, string)`
    *   `DisableVertexAttribArray(uint)`
    *   `GetFloat(GLEnum, out float)`
*   **Modern GLSL Migrations (`chunk.frag`, `chunk.vert`):** The default shaders were force-upgraded to `#version 410` by upstream but retained deprecated GLSL 120 syntax. We converted `attribute` to `in`, `varying` to `in/out`, and `texture2D` to `texture` internally, guaranteeing Core Profile compilation on strict systems.

## 4. Stability Fixes
*   **FPS Timer Fix (`GameRenderer.cs`):** Corrected the layout of the 240+ Hz FPS unlocker so the timer restarts outside of the frame limiter block, ensuring smooth sub-millisecond deltas instead of stuttering.
