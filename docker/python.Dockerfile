FROM python

COPY ../ /root/git-hooks/
WORKDIR /root/git-hooks/

RUN pip install --requirement './requirements-dev.txt'
