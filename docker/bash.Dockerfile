FROM python

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        shfmt \
        shellcheck \
        bats \
    && rm --force --recursive /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash python
USER python

COPY --chown=python . /home/python/repo/
WORKDIR /home/python/repo/

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]
CMD source './git-hooks/src/ci.sh' && run_ci_bash
