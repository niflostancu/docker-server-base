# S6-powered base container image

Personal base container image built on [Alpine Linux](https://alpinelinux.org/) & [S6 Overlay](https://github.com/just-containers/s6-overlay).

**Features:**

- [s6-rc](https://skarnet.org/software/s6-rc/)-based init system;
- common init ops for custom UID/GID & timezone configuration (based on env.
  vars);
- script for waiting (useful in tests & readiness probes!);
- build (Makefile-based) & testing framework (based on [goss](https://github.com/goss-org/goss/));

## Usage

Simply inherit the `niflostancu/server-base` image and add your files / services.

Make sure to read the [S6 Overlay](https://github.com/just-containers/s6-overlay)'s readme.

You will also need to familiarize yourself with [s6-rc](https://skarnet.org/software/s6-rc/)'s philosophy & API.

_TODO: add example images built with it_


## Building

You might want to read the included [Makefile's code](./Makefile).

A simple `make` will suffice!
This will fetch the latest S6 overlay version and build the base image.

You might want to customize the Docker Registry prefix. To do that, simply create
a `local.mk` file with variable overrides:

```make
# local.mk (gitignored)
IMAGE_PREFIX = mydockerimagerepo/
```

If you want to push the image to a repository: `make push`.

## Testing

The project includes a [`goss`](https://github.com/goss-org/goss/)-powered
testing framework! To run them (on a locally-built image):

```sh
make test
```

Check out the [test scripts'](./test/) source code.
You may want to test your new container image!

