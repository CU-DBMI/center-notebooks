
package main

import (
    "dagger.io/dagger"
    "universe.dagger.io/docker"
    "universe.dagger.io/docker/cli"
)

dagger.#Plan & {
    client: {
        filesystem: "./": read: contents: dagger.#FS
        network: "unix:///var/run/docker.sock": connect: dagger.#Socket
        env: PWD: string
    }
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
        // build docker-in-docker image for testing github actions with act
        dind_build: docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "docker:git"
                },
                docker.#Run & {
                    command: {
                        name: "mkdir"
                        args: ["/home/work"]
                    }
                },
                docker.#Copy & {
                    contents: client.filesystem."./".read.contents
                    source: "./"
                    dest: "/home/work/"
                },
                docker.#Run & {
                    workdir: "/home/work"
                    command: {
                        name: "wget"
                        args: ["https://raw.githubusercontent.com/nektos/act/master/install.sh"]
                    }
                },
                docker.#Run & {
                    workdir: "/home/work"
                    command: {
                        name: "chmod"
                        args: ["755", "install.sh"]
                    }
                },
                docker.#Run & {
                    workdir: "/home/work"
                    command: {
                        name: "./install.sh"
                    }
                },
            ]
        }

        // build jupyter development image
        jupyter_build: docker.#Dockerfile & {
                source: client.filesystem."./".read.contents
                dockerfile: path: "./jupyter-dev.Dockerfile"
        }
        // load the jupyter dev image to local docker instance
        jupyter_local_load: cli.#Load & {
            image: jupyter_build.output
            host:  client.network."unix:///var/run/docker.sock".connect
            tag:   "jupyter-dev"
        }
        // run jupyter development image in local docker cli
        jupyter_local_run: {
            cli.#Run & {
                input: jupyter_local_load.output
                host: client.network."unix:///var/run/docker.sock".connect
                command: {
                    name: "run"
                    args: ["-d", "--name", "jupyter-dev", 
                            "-p", "8888:8888",
                            "-v", client.env.PWD + "/src:/workdir/src",
                            "jupyter-dev"]
                }
            }
        }
        // lint
        lint: {
            // lint dockerfile
            hadolint: docker.#Run & {
                input: hadolint_build.output
                command: {
                        name: "/bin/hadolint"
                        args: ["/tmp/jupyter-dev.Dockerfile"]
                }
            }
            // lint yaml files
            yaml: docker.#Run & {
                input: python_build.output
                command: {
                    name: "python"
                    args: ["-m", "yamllint", "src/Notebooks"]
                }
            }
            // lint python and notebook files
            black: docker.#Run & {
                input: python_build.output
                command: {
                    name: "python"
                    args: ["-m", "black", "src/Notebooks", "--check"]
                }
            }
        }
        test: {
            // test github actions
            github_actions: docker.#Run & {
                input: dind_build.output
                workdir: "/home/work"
                command: {
                    name: "/home/work/bin/act"
                    args: ["-P", "node:16-buster-slim"]
                }
            }
        }
    }
}

