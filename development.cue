
package main

import (
    "dagger.io/dagger"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
    client: filesystem: "./": read: contents: dagger.#FS
    python_version: string | *"3.9.12"

    actions: {
        // build hadolint image
        hadolint_build: docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "hadolint/hadolint:latest-debian"
                },
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    source:"./*.Dockerfile"
                    dest: "/tmp/"
                },
            ]
        }
        // build base python image for linting and testing
        python_build: docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "python:" + python_version
                },
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    source:"./requirements.txt"
                    dest: "./"
                },
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    source:"./src/Notebooks/"
                    dest: "./src/Notebooks/"
                },
                docker.#Run & {
                    command: {
                        name: "pip" 
                        args: ["install","--no-cache-dir","-r","requirements.txt"]
                    }
                },
            ]
        }
        // build jupyter development image
        jupyter_build: docker.#Dockerfile & {
                source: client.filesystem."./".read.contents
                dockerfile: path: "./jupyter-dev.Dockerfile"
        }
        // lint
        lint: {
            // lint dockerfile
            hadolint_lint: docker.#Run & {
                input: hadolint_build.output
                command: {
                        name: "/bin/hadolint"
                        args: ["/tmp/jupyter-dev.Dockerfile"]
                }
            }
            // lint yaml files
            yaml_lint: docker.#Run & {
                input: python_build.output
                command: {
                    name: "python"
                    args: ["-m", "yamllint", "src/Notebooks"]
                }
            }
            // lint python and notebook files
            black_lint: docker.#Run & {
                input: python_build.output
                command: {
                    name: "python"
                    args: ["-m", "black", "src/Notebooks", "--check"]
                }
            }
        }
    }
}

