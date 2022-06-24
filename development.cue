package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

// python build for linting, testing, building, etc.
#PythonBuild: {
	// client filesystem
	filesystem: dagger.#FS

	// python version to use for build
	python_ver: string | *"3.9"

	// poetry version to use for build
	poetry_ver: string | *"1.1.13"

	// container image
	output: python_build.output

	// referential build for base python image
	_python_pre_build: docker.#Build & {
		steps: [
			docker.#Pull & {
				source: "python:" + python_ver
			},
			docker.#Run & {
				command: {
					name: "mkdir"
					args: ["/workdir"]
				}
			},
			docker.#Copy & {
				contents: filesystem
				source:   "./pyproject.toml"
				dest:     "/workdir/pyproject.toml"
			},
			docker.#Copy & {
				contents: filesystem
				source:   "./poetry.lock"
				dest:     "/workdir/poetry.lock"
			},
			docker.#Run & {
				workdir: "/workdir"
				command: {
					name: "pip"
					args: ["install", "--no-cache-dir", "poetry==" + poetry_ver]
				}
			},
			docker.#Set & {
				config: {
					env: ["POETRY_VIRTUALENVS_CREATE"]: "false"
				}
			},
			docker.#Run & {
				workdir: "/workdir"
				command: {
					name: "poetry"
					args: ["install", "--no-interaction", "--no-ansi"]
				}
			},
		]
	}
	// python build with likely changes
	python_build: docker.#Build & {
		steps: [
			docker.#Copy & {
				input:    _python_pre_build.output
				contents: filesystem
				source:   "./"
				dest:     "/workdir"
			},
		]
	}
}

// Convenience cuelang build for formatting, etc.
#CueBuild: {
	// client filesystem
	filesystem: dagger.#FS

	// output from the build
	output: _cue_build.output

	// cuelang pre-build
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
	// cue build for actions in this plan
	_cue_build: docker.#Build & {
		steps: [
			docker.#Copy & {
				input:    _cue_pre_build.output
				contents: filesystem
				source:   "./project.cue"
				dest:     "/workdir/project.cue"
			},
		]
	}

}


dagger.#Plan & {

	client: {
		filesystem: {
			"./": read: contents:                 dagger.#FS
			"./center-notebooks/Notebooks": write: contents:   actions.clean.remove_jupyter_output.export.directories."/workdir/center-notebooks/Notebooks"
			"./center-notebooks": write: contents:             actions.clean.black.export.directories."/workdir/center-notebooks"
			"./development.cue": write: contents: actions.clean.cue.export.files."/workdir/development.cue"
		}
	}
	python_version: string | *"3.9"
	poetry_version: string | *"1.1.13"

	actions: {

		python_build: #PythonBuild & {
			filesystem: client.filesystem."./".read.contents
			python_ver: python_version
			poetry_ver: poetry_version
		}

		cue_build: #CueBuild & {
			filesystem: client.filesystem."./".read.contents
		}

		// applied code and/or file formatting
		clean: {
			// sort python imports with isort
			isort: docker.#Run & {
				input:   python_build.output
				workdir: "/workdir"
				command: {
					name: "poetry"
					args: ["run", "isort", "/workdir/center-notebooks/"]
				}
				export: {
					directories: "/workdir/center-notebooks": _
				}
			}
			// code style formatting with black
			black: docker.#Run & {
				input:   isort.output
				workdir: "/workdir"
				command: {
					name: "poetry"
					args: ["run", "black", "/workdir/center-notebooks/"]
				}
				export: {
					directories: "/workdir/center-notebooks": _
				}
			}
			// remove jupyter notebook output data
			remove_jupyter_output: docker.#Run & {
				input:   black.output
				workdir: "/workdir"
				command: {
					name: "find"
					args: ["/workdir/center-notebooks/Notebooks", "-name", "*.ipynb",
						"-exec", "poetry", "run", "jupyter", "nbconvert",
						"--clear-output", "--inplace",
						"{}", "+"]
				}
				export: {
					directories: "/workdir/center-notebooks/Notebooks": _
				}
			}
			// code formatting for cuelang
			cue: docker.#Run & {
				input:   cue_build.output
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
			// lint yaml files
			yaml: docker.#Run & {
				input:   python_build.output
				workdir: "/workdir"
				command: {
					name: "poetry"
					args: ["run", "yamllint", "center-notebooks/Notebooks"]
				}
			}
			// lint python and notebook files
			black: docker.#Run & {
				input:   python_build.output
				workdir: "/workdir"
				command: {
					name: "poetry"
					args: ["run", "black", "center-notebooks/Notebooks", "--check"]
				}
			}
		}
	}
}
