FROM redis:8.0.0-alpine

LABEL maintainer="Haouari Haitam <haouarikh@gmail.com>"
LABEL license="AGPL-3.0"
LABEL org.opencontainers.image.source="https://github.com/redis/redis"
LABEL org.opencontainers.image.licenses="AGPL-3.0"

COPY ./LICENSE.md /usr/share/licenses/redis/LICENSE
COPY ./NOTICE.md /usr/share/licenses/redis/NOTICE
COPY ./SOURCE_INFO.md /usr/share/licenses/redis/SOURCE_INFO

EXPOSE 6379

CMD ["redis-server"]