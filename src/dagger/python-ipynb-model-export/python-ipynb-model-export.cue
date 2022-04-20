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

    // location to export model
    model_export_dir: string

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
                config: { 
                    volume: {[model_export_dir + ":/src/notebooks/exports"] : {} }
                    cmd: ["python", "-m", "papermill", 
                        "/src/notebooks/put-model.ipynb", 
                        "/src/notebooks/exports/put-model-output.ipynb"]
                }
            }
        ]
    }
}

dagger.#Plan & {
    client: {
        filesystem: {
            "./src": read: contents: dagger.#FS
        }
        env: {
            // load export dir as a string from environment var
            MODEL_EXPORT_DIR: string
        }
    }

    actions: {
        // build reproducible python environment for exporting model
        build: #PythonBuild & {
            // specify location of python app
            app: client.filesystem."./src".read.contents
            
            // specify python version to use with build
            python_version: "3.9"

            // specify where to export model
            model_export_dir: client.env.MODEL_EXPORT_DIR
        }

        // export model from python environement
        export: docker.#Run & {
            input: build._build.output
        }
    }
}