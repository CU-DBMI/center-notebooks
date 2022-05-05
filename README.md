# center-notebooks

Python Jupyter notebooks for pre-production or one-off experiments.

To install required Python packages:

    pip install -r requirements.txt

To run a notebook using Papermill,

    cd src/Notebooks
    papermill --log-output "Create Cites from PMC Lookups.ipynb" -

## Local Development with Docker

A local development environment is available through local containerized environment using [Dagger](https://docs.dagger.io/). Use the following steps to run this environment.

1. [Install Dagger](https://docs.dagger.io/1200/local-dev)
1. Open a terminal and navigate to the directory of this source.
1. Use `dagger project update` to populate dependencies.
1. Use `dagger do jupyter_local_run` to build and run a jupyter lab container
1. After the Dagger action completes, Open a browser window to [http://localhost:8888/lab](http://localhost:8888/lab)
