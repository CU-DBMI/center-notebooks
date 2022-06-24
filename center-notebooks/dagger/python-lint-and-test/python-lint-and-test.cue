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
                dest:     "/src"
            },
            docker.#Run & {
                command: {
                    name: "pip"
                    args: ["install", "-r", "/src/requirements.txt"]
                }
            },
            docker.#Set & {
                config: cmd: ["python", "/src/app/app.py"]
            },
        ]
    }
}

dagger.#Plan & {
    client: filesystem: "./src": read: contents: dagger.#FS

    // template to build multiple versions of python app
    actions:
        builds: {
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

            lint: docker.#Run & {
                input: build._build.output
                command: {
                    name: "python"
                    args: ["-m", "pylint", "/src"]
                }
            }

            test: docker.#Run & {
                input: build._build.output
                command: {
                    name: "python"
                    args: ["-m", "pytest", "/src"]
                }
            }
        }
    }
}