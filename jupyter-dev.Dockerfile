# references (but not copies)
# - https://github.com/jupyterhub/jupyterhub/blob/main/dockerfiles/Dockerfile.alpine
# - https://github.com/jupyterhub/repo2docker/blob/main/Dockerfile

ARG PYTHON_VERSION=3.9.12

FROM python:$PYTHON_VERSION

ENV LANG=en_US.UTF-8

ENV PWD=$PWD
ENV DATA_PWD=$PWD
ENV WORK_DIR=/workdir

WORKDIR $WORK_DIR

COPY $DATA_PWD $WORK_DIR

# add a nonroot user
RUN groupadd --system somebody \
    && useradd --system --gid somebody -G root somebody \
    && mkdir /home/somebody

# update to enable nonroot access
RUN chgrp -R 0 $WORK_DIR \
    && chgrp -R 0 /home/somebody \ 
    && chmod -R g=u $WORK_DIR \
    && chmod -R g=u /home/somebody

# installs
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    nodejs \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN pip3 install --no-cache-dir -r requirements.txt

# Install and enable jupyter lab formatter extension for isort+black formatting within notebooks
RUN jupyter labextension install @ryantam626/jupyterlab_code_formatter \
    && jupyter serverextension enable --py jupyterlab_code_formatter \
    && jupyter server extension enable jupyterlab_code_formatter

USER somebody

EXPOSE 8888

CMD ["jupyter","lab" \
    ,"--ip", "0.0.0.0" \
    ,"--no-browser" \
    ,"--ServerApp.token=''" \
    ,"--ServerApp.password=''"]