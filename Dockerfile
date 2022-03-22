FROM python:3

RUN adduser --disabled-password --disabled-login myuser

WORKDIR /opt/semantle

RUN curl -O https://s3.amazonaws.com/dl4j-distribution/GoogleNews-vectors-negative300.bin.gz && \
    gunzip GoogleNews-vectors-negative300.bin.gz

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY british.py	\
     dump-hints.py \
     dump-vecs.py \
     store-hints.py \
     banned.txt \
     words_alpha.txt \
     .

RUN python dump-vecs.py

COPY static ./static

RUN python dump-hints.py
RUN python store-hints.py

COPY semantle.py \
     british_spellings.json \
     templates \
     .

RUN python british.py

RUN chown -R myuser .

USER myuser

EXPOSE $PORT

CMD [ "sh", "-c", "gunicorn --bind 0.0.0.0:$PORT semantle:app" ]

