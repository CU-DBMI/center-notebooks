# center-notebooks

Python Jupyter notebooks for pre-production or one-off experiments.

## Installation

Use Python [poetry](https://python-poetry.org/) to run and install related packages.

```shell
# installation
poetry install
```

## Running Notebooks

To run a notebook using [Papermill](https://papermill.readthedocs.io/en/latest/index.html):

```shell
# navigate to Notebooks dir
cd center-notebooks/Notebooks
# run a notebook using papermill cmd
papermill --log-output "Create Cites from PMC Lookups.ipynb" -
```

## Development

Development is assisted by procedures using [Dagger](https://dagger.io) via the `development.cue` file within this repo. These are also related to checks which are performed related to CI/CD. See the following page for more information on installing Dagger: <https://docs.dagger.io/install>

Afterwards, use the following commands within the project directory to perform various checks. Warnings or errors should show the related file and relevant text from the related tool which may need to be addressed.

```shell
# clean various files using formatting standards
dagger do clean
# lint the files for formatting or other issues
dagger do lint
# perform testing on the files
dagger do test
...
```
