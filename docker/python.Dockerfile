FROM python

ARG REPO_NAME=repo
ARG CI_SCRIPT_PATH=./git-hooks/src/ci.sh
ENV CI_SCRIPT_PATH=$CI_SCRIPT_PATH

RUN useradd --create-home --shell /bin/bash python
USER python

COPY --from=astral/uv /uv /bin/

COPY --chown=python pyproject.toml uv.lock /home/python/$REPO_NAME/
WORKDIR /home/python/$REPO_NAME/
RUN uv sync --no-cache

COPY --chown=python . /home/python/$REPO_NAME/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source "$CI_SCRIPT_PATH" && run_ci_python
