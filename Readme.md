# Get Common Architectures from Docker Containers

Give this action a list of images, and it'll tell you what architectures they support as a whole.

Useful for emulating tests for a variety of images at once but only on architectures where they'll all work.

<!-- action-docs-inputs -->
## Inputs

| parameter | description | required | default |
| - | - | - | - |
| images | input_delimiter separated list of Docker images to get architectures from | `true` |  |
| prune_missing_images | Remove results from images that don't exist or have no results (after querying manifest and inspecting the image) | `false` | true |
| default_architectures | input_delimiter separated list of architectures to use if none are found or if the image doesn't exist | `false` | linux/amd64 |
| debug | Enable debug logging | `false` | false |
| input_delimiter | Delimiter to use when splitting the images and default_architectures input | `false` | , |
| output_delimiter | Delimiter to use when joining the architectures output | `false` | , |



<!-- action-docs-inputs -->

<!-- action-docs-outputs -->
## Outputs

| parameter | description |
| - | - |
| architectures | output_delimiter separated list of architectures common between all images |



<!-- action-docs-outputs -->

<!-- action-docs-runs -->
## Runs

This action is a `composite` action.


<!-- action-docs-runs -->
