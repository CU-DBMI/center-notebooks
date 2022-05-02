
package main

import (
    "dagger.io/dagger"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
    client: filesystem: "./": read: contents: dagger.#FS

    actions: {
        // build hadolint image
        hadolint_build: docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "hadolint/hadolint:latest-debian"
                },
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    source:"./jupyter-dev.Dockerfile"
                    dest: "/tmp/jupyter-dev.Dockerfile"
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
                input: jupyter_build.output
                command: {
                    name: "python"
                    args: ["-m", "yamllint", "src/Notebooks"]
                }
            }
            // lint python and notebook files
            black_lint: docker.#Run & {
                input: jupyter_build.output
                command: {
                    name: "python"
                    args: ["-m", "black", "src/Notebooks", "--check"]
                }
            }
        }
    }
}

