# Get Common Architectures from Docker Containers

Give this action a list of images, and it'll tell you what architectures they support as a whole.

Useful for emulating tests for a variety of images at once but only on architectures where they'll all work.

## Usage

```yaml
jobs:
  get_architectures:
    runs-on: ubuntu-latest
    outputs:
      list: ${{ steps.arch.outputs.list }}
    steps:
      - uses: Makeshift/get-common-docker-architectures@master
        id: arch
        with:
          images: alpine:3.16.0,centos:centos7.9.2009,debian:stable-20220822-slim
    
  run_on_each_arch:
    runs-on: ubuntu-latest
    needs: get_architectures
    strategy:
      matrix:
        arch: ${{ fromJson(need.get_architectures.outputs.list) }}
    steps:
      - run: echo "${{ matrix.arch }}"
```

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
