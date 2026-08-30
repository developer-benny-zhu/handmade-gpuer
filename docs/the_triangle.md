# The Triangle

Now we got our window up and running, its finally time to render a triangle! Before then you must understand a few concepts.

## Vertex

A vertex is simply a point. In the triangle below, it has three vertices.

![Triangle With Vertices](assets/triangle_with_vertices.png)

## Vertex Shader

A vertex shader is a program that runs on the GPU for ever vertex you give it. From that phrase alone, the concept of a vertex shader may seem a little abstract, so lets imagine a triangle ABC at the centered at the origin of the window:

![Triangle With ABC At Origin](assets/triangle_abc_at_origin.png)

??? note "Wait how is that the origin of the window?"
    This is called screen coordinates the origin is the top left of the window and X increases as you move right and Y increases as you move down.
    ![Screen Coordinates](assets/screen_coordinates.png)

Mentioned again, the vertex shader runs every for each of these vertices.

```mermaid
flowchart TD
        A["Vertex A"]
        B["Vertex B"]
        C["Vertex C"]
        Shader["Vertex Shader"]
        NPFVA["New Position For Vertex A"]
        NPFVB["New Position For Vertex B"]
        NPFVC["New Position For Vertex C"]
        A-->Shader
        B-->Shader
        C-->Shader
        Shader-->NPFVA
        Shader-->NPFVB
        Shader-->NPFVC
```

Now after running through the vertex shader, we see that the triangle is now centered on the window.

![Triangle With ABC At Center](assets/triangle_abc_at_center.png)

Of course you don't necessarily have to center the triangle you could move it anywhere you want.

## Rasterization

Rasterization is the process of converting a mathematical triangle into fragments... wait a second... the hell is a fragment? Well lets slow down for a second.

Remember that your screen is made up of pixels:
![Pixel Grid](assets/pixel_grid.png)

Now lets put points on this screen representing a triangle.

![Pixel Grid With Unrasterized Triangle](assets/pixel_grid_with_unrasterized_triangle.png)

Now you fill in the triangle with pixels.

![Pixel Grid With Rasterized Triangle](assets/pixel_grid_with_rasterized_triangle.png)

That is rasterization. It produces fragments. Huh? Wait a second... what is a fragment? Well, a fragment is a potential pixel generated when the GPU rasterizes the triangle produced by the vertex shader.

<details>
<summary>What do you mean potential pixel?</summary>

A fragment isn't guaranteed to become a pixel in the final image. Imagine if there are two triangles overlapping, both triangles are rasterized but one triangle is in front of the other and some fragments of one triangle cannot be shown.

</details>

Congratulation! You now have a rainbow triangle!

![Rainbow Triangle](assets/the_triangle.png)

```

```
