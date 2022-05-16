package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
	"universe.dagger.io/docker/cli"
)

dagger.#Plan & {

	client: {
		filesystem: {
			"./": read: contents:                 dagger.#FS
			"./src/Notebooks": write: contents:   actions.clean.remove_jupyter_output.export.directories."/workdir/src/Notebooks"
			"./src": write: contents:             actions.clean.black.export.directories."/workdir/src"
			"./development.cue": write: contents: actions.clean.cue.export.files."/workdir/development.cue"
		}
		platform: {
			os: string | *"linux"
		}
		network: "unix:///var/run/docker.sock": connect: dagger.#Socket
		if client.platform.os == "windows" {
			network: "npipe:////./pipe/docker_engine": connect: dagger.#Socket
		}
		env: PWD: string
	}
	python_version: string | *"3.9.12"

	actions: {
		// build hadolint image
		_hadolint_build: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "hadolint/hadolint:latest-debian"
				},
				docker.#Copy & {
					contents: client.filesystem."./".read.contents
					source:   "./*.Dockerfile"
					dest:     "/tmp/"
				},
			]
		}
		// build base python image for linting and testing
		_python_pre_build: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "python:" + python_version
				},
				docker.#Run & {
					command: {
						name: "mkdir"
						args: ["/workdir"]
					}
				},
				docker.#Copy & {
					contents: client.filesystem."./".read.contents
					source:   "./requirements.txt"
					dest:     "/workdir/requirements.txt"
				},
				docker.#Run & {
					workdir: "/workdir"
					command: {
						name: "pip"
						args: ["install", "--no-cache-dir", "-r", "requirements.txt"]
					}
				},
			]
		}
		_python_build: docker.#Build & {
			steps: [
				docker.#Copy & {
					input:    _python_pre_build.output
					contents: client.filesystem."./".read.contents
					source:   "./"
					dest:     "/workdir"
				},
			]
		}
		// build jupyter development image
		_jupyter_build: docker.#Dockerfile & {
			source: client.filesystem."./".read.contents
			dockerfile: path: "./jupyter-dev.Dockerfile"
		}
		// load the jupyter dev image to local docker instance
		_jupyter_local_load: cli.#Load & {
			image: _jupyter_build.output
			host:  client.network."unix:///var/run/docker.sock".connect
			if client.platform.os == "windows" {
				host: client.network."npipe:////./pipe/docker_engine".connect
			}
			tag: "jupyter-dev"
		}
        // build jupyter development image
		_jupyter_nextflow_build: docker.#Dockerfile & {
			source: client.filesystem."./".read.contents
			dockerfile: path: "./jupyter-nextflow-dev.Dockerfile"
		}
		// load the jupyter dev image to local docker instance
		_jupyter_nextflow_local_load: cli.#Load & {
			image: _jupyter_build.output
			host:  client.network."unix:///var/run/docker.sock".connect
			if client.platform.os == "windows" {
				host: client.network."npipe:////./pipe/docker_engine".connect
			}
			tag: "jupyter-nextflow-dev"
		}
		// cuelang pre build
		_cue_pre_build: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "golang:latest"
				},
				docker.#Run & {
					command: {
						name: "mkdir"
						args: ["/workdir"]
					}
				},
				docker.#Run & {
					command: {
						name: "go"
						args: ["install", "cuelang.org/go/cmd/cue@latest"]
					}
				},
			]
		}
		// cuelang build for actions in this plan
		_cue_build: docker.#Build & {
			steps: [
				docker.#Copy & {
					input:    _cue_pre_build.output
					contents: client.filesystem."./".read.contents
					source:   "./development.cue"
					dest:     "/workdir/development.cue"
				},
			]
		}
		// run jupyter development image in local docker cli
		jupyter: {
			cli.#Run & {
				input: _jupyter_local_load.output
				host:  client.network."unix:///var/run/docker.sock".connect
				if client.platform.os == "windows" {
					host: client.network."npipe:////./pipe/docker_engine".connect
				}
				command: {
					name: "run"
					args: ["-d", "--name", "jupyter-dev",
						"-p", "8888:8888",
						"-v", client.env.PWD + ":/workdir",
						"jupyter-dev"]
				}
			}
		}
        // run jupyter development image in local docker cli
		jupyter_nextflow: {
			cli.#Run & {
				input: _jupyter_nextflow_local_load.output
				host:  client.network."unix:///var/run/docker.sock".connect
				if client.platform.os == "windows" {
					host: client.network."npipe:////./pipe/docker_engine".connect
				}
				command: {
					name: "run"
					args: ["-d", "--name", "jupyter-nextflow-dev",
						"-p", "8899:8888",
						"-v", client.env.PWD + ":/workdir",
						"jupyter-nextflow-dev"]
				}
			}
		}
		// applied code and/or file formatting
		clean: {
			// sort python imports with isort
			isort: docker.#Run & {
				input:   _python_build.output
				workdir: "/workdir"
				command: {
					name: "python"
					args: ["-m", "isort", "/workdir/src/"]
				}
				export: {
					directories: "/workdir/src": _
				}
			}
			// code style formatting with black
			black: docker.#Run & {
				input:   isort.output
				workdir: "/workdir"
				command: {
					name: "python"
					args: ["-m", "black", "/workdir/src/"]
				}
				export: {
					directories: "/workdir/src": _
				}
			}
			// remove jupyter notebook output data
			remove_jupyter_output: docker.#Run & {
				input:   black.output
				workdir: "/workdir"
				command: {
					name: "find"
					args: ["/workdir/src/Notebooks", "-name", "*.ipynb",
						"-exec", "python", "-m", "jupyter", "nbconvert",
						"--clear-output", "--inplace",
						"{}", "+"]
				}
				export: {
					directories: "/workdir/src/Notebooks": _
				}
			}
			// code formatting for cuelang
			cue: docker.#Run & {
				input:   _cue_build.output
				workdir: "/workdir"
				command: {
					name: "cue"
					args: ["fmt", "/workdir/development.cue"]
				}
				export: {
					files: "/workdir/development.cue": _
				}
			}
		}
		// lint
		lint: {
			// lint dockerfile
			hadolint: docker.#Run & {
				input:   _hadolint_build.output
				workdir: "/workdir"
				command: {
					name: "/bin/hadolint"
					args: ["/tmp/*Dockerfile"]
				}
			}
			// lint yaml files
			yaml: docker.#Run & {
				input:   _python_build.output
				workdir: "/workdir"
				command: {
					name: "python"
					args: ["-m", "yamllint", "src/Notebooks"]
				}
			}
			// lint python and notebook files
			black: docker.#Run & {
				input:   _python_build.output
				workdir: "/workdir"
				command: {
					name: "python"
					args: ["-m", "black", "src/Notebooks", "--check"]
				}
			}
		}
	}
}
