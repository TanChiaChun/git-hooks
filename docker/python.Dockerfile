FROM python

ARG REPO_NAME=repo
ARG GIT_HOOKS_REQUIREMENTS_SRC=git-hooks/requirements*.txt
ARG GIT_HOOKS_REQUIREMENTS_DEST=/home/python/$REPO_NAME/git-hooks/
ARG CI_SCRIPT_PATH=./git-hooks/src/ci.sh
ENV CI_SCRIPT_PATH=$CI_SCRIPT_PATH

RUN useradd --create-home --shell /bin/bash python
USER python

COPY --chown=python requirements*.txt /home/python/$REPO_NAME/
COPY --chown=python $GIT_HOOKS_REQUIREMENTS_SRC $GIT_HOOKS_REQUIREMENTS_DEST
WORKDIR /home/python/$REPO_NAME/
RUN pip install --no-cache-dir --requirement './requirements-dev.txt' \
    && mkdir --parents .venv/bin
ENV PATH="/home/python/.local/bin:$PATH"

COPY --chown=python . /home/python/$REPO_NAME/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source "$CI_SCRIPT_PATH" && run_ci_python
