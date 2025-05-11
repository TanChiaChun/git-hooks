FROM python

ARG REPO_NAME=repo

RUN useradd --create-home --shell /bin/bash python
USER python

COPY --chown=python requirements*.txt /home/python/$REPO_NAME/
WORKDIR /home/python/$REPO_NAME/
RUN pip install --requirement './requirements-dev.txt' \
    && rm --force --recursive "$(pip cache dir)" \
    && mkdir --parents venv/bin
ENV PATH="/home/python/.local/bin:$PATH"

COPY --chown=python . /home/python/$REPO_NAME/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './src/ci.sh' && run_ci_python
