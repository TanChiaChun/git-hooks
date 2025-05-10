FROM python

RUN useradd --create-home --shell /bin/bash python
USER python

ENV PATH="/home/python/.local/bin:$PATH"

COPY --chown=python ../ /home/python/git-hooks/
WORKDIR /home/python/git-hooks/

RUN pip install --requirement './requirements-dev.txt'

SHELL ["/bin/bash", "-c"]
CMD source './src/ci.sh' \
    && run_ci_python_black \
    && run_ci_python_pylint \
    && run_ci_python_mypy \
    && run_ci_python_isort \
    && run_ci_python_test_unittest
