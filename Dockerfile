# syntax=docker/dockerfile:1
FROM alpine:latest as build
ARG VERSION='0.8.2'

WORKDIR '/home'

RUN apk add coreutils gpg gpg-agent unzip curl


# https://releases.hashicorp.com/serf/0.8.2/serf_0.8.2_linux_amd64.zip?_ga=2.40913698.1805434005.1684239028-1174127321.1681512790
ENV BASE_URL='https://releases.hashicorp.com'
ENV APPLICATION='serf'
ENV URL="${BASE_URL}/${APPLICATION}/${VERSION}"
ENV GA='2.237652480.1805434005.1684239028-1174127321.1681512790'
ENV TARGET='linux_amd64'
ENV FILE="${APPLICATION}_${VERSION}_${TARGET}.zip"
ENV SHAFILE="${APPLICATION}_${VERSION}_SHA256SUMS"
ENV SIGFILE="${SHAFILE}.sig"

RUN curl -o 'hashicorp.asc' 'https://www.hashicorp.com/.well-known/pgp-key.txt'
RUN curl -O "${URL}/${SHAFILE}?_ga=${GA}"  
RUN curl -O "${URL}/${SIGFILE}?_ga=${GA}"

RUN gpg --import 'hashicorp.asc'
RUN curl -O "${URL}/${FILE}?_ga=${GA}" 

RUN gpg --verify "$SIGFILE" "$SHAFILE"
RUN grep "$FILE" "$SHAFILE" > "SHAFILE_FILTERED"
RUN sha256sum -c "SHAFILE_FILTERED"
RUN unzip "$FILE"


FROM alpine:latest
COPY --from=build /home/serf /bin/serf
RUN addgroup -g 1000 serf && adduser --uid 1000 -S serf -G serf
USER 1000
ENTRYPOINT ["/bin/serf"]
CMD ["agent"]
