FROM python

ARG REPO_NAME=repo
ARG CI_SCRIPT_PATH=./git-hooks/src/ci.sh
ENV CI_SCRIPT_PATH=$CI_SCRIPT_PATH

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        pipx \
    && rm --force --recursive /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash python
USER python

RUN pipx install poetry
ENV PATH="/home/python/.local/bin:$PATH"

COPY --chown=python poetry.toml /home/python/$REPO_NAME/
COPY --chown=python pyproject.toml /home/python/$REPO_NAME/
WORKDIR /home/python/$REPO_NAME/
RUN poetry sync

COPY --chown=python . /home/python/$REPO_NAME/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source "$CI_SCRIPT_PATH" && run_ci_python
