// referenced with modifications from: https://docs.dagger.io/1205/container-images
package main

import (
    "dagger.io/dagger"
    "universe.dagger.io/docker"
)

// This action builds a docker image from a python app.
// Build steps are defined in native CUE.
#PythonBuild: {
    // Source code of the Python application
    app: dagger.#FS

    // python version to use for build
    python_version: string | *"3.9"

    // container image
    image: _build.output

    // build image
    _build: docker.#Build & {
        steps: [
            docker.#Pull & {
                source: "python:\(python_version)"
            },
            docker.#Copy & {
                contents: app
                dest:     "/app"
            },
            docker.#Run & {
                command: {
                    name: "pip"
                    args: ["install", "-r", "/app/requirements.txt"]
                }
            },
            docker.#Set & {
                config: cmd: ["python", "/app/app.py"]
            },
        ]
    }
}

dagger.#Plan & {
    client: filesystem: "./src": read: contents: dagger.#FS

    // template to build multiple versions of python app
    actions:
        versions: {
        // python versions to reference for builds
        "3.9": _
        "3.8": _

        [version=string]: {
            build: #PythonBuild & {
                // specify location of python app
                app: client.filesystem."./src".read.contents
                // specify python version to use with build
                python_version: "\(version)"
            }
        }
    }
}