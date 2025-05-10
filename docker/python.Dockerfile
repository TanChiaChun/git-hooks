FROM python

RUN useradd --create-home --shell /bin/bash python
USER python

ENV PATH="/home/python/.local/bin:$PATH"

COPY --chown=python ../ /home/python/git-hooks/
WORKDIR /home/python/git-hooks/

RUN pip install --requirement './requirements-dev.txt' \
    && mkdir --parents venv/bin

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './src/ci.sh' && run_ci_python
