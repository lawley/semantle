FROM python:3 AS build

WORKDIR /opt/semantle

RUN curl -O https://s3.amazonaws.com/dl4j-distribution/GoogleNews-vectors-negative300.bin.gz && \
    gunzip GoogleNews-vectors-negative300.bin.gz

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt && \
    mkdir -p static/assets/js

COPY static/assets/js/secretWords.js \
     static/assets/js/.

COPY british.py	\
     dump-hints.py \
     dump-vecs.py \
     store-hints.py \
     banned.txt \
     words_alpha.txt \
     british_spellings.json \
     .

RUN python dump-vecs.py
RUN python dump-hints.py
RUN python store-hints.py
RUN python british.py

FROM --platform=linux/amd64 python:3

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN adduser --disabled-password --disabled-login myuser
USER myuser

WORKDIR /opt/semantle

COPY --chown=myuser --from=build \
     /opt/semantle ./

COPY --chown=myuser \
     semantle.py \
     templates \
     .
COPY --chown=myuser static tmp_static
RUN cp -R tmp_static/* static && rm -rf tmp_static

EXPOSE $PORT

CMD [ "sh", "-c", "gunicorn --bind 0.0.0.0:$PORT semantle:app" ]

