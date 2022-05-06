# center-notebooks

Python Jupyter notebooks for pre-production or one-off experiments.

To install required Python packages:

    pip install -r requirements.txt

To run a notebook using Papermill,

    cd src/Notebooks
    papermill --log-output "Create Cites from PMC Lookups.ipynb" -

## Dagger Tooling

Development and integration may be assisted using [Dagger](https://docs.dagger.io/) and related files within this repo. Use the following steps to get started:

1. [Install Dagger](https://docs.dagger.io/1200/local-dev)
1. Open a terminal and navigate to the directory of this source.
1. Use `dagger project update` to populate dependencies.

### Formatting

To lint using Dagger use the command `dagger do format`. This applies isort and black formatting, in addition to clearing any notebook output.

### Linting

To lint using Dagger use the command `dagger do lint`. This will perform various linting steps intended to assist with code quality, formatting, etc.

### Local Containerized Jupyter Environment

A local containerized Jupyter development environment is available for convenience. This environment generally depends on Docker being installed on the local machine. Use the following steps to run this environment.

1. Use `dagger do jupyter_local_run` to build and run a jupyter lab container
1. After the Dagger action completes, Open a browser window to [http://localhost:8888/lab](http://localhost:8888/lab)
