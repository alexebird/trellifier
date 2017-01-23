FROM ubuntu
RUN apt-get update && \
    apt-get install -y libssl1.0.0 postgresql-client && \
    apt-get autoclean
RUN mkdir -p /app
ARG VERSION=0.0.1
ENV APP_NAME trellifier
COPY rel/${APP_NAME}/${APP_NAME}-${VERSION}.tar.gz /app/${APP_NAME}.tar.gz
WORKDIR /app
RUN tar xvzf ${APP_NAME}.tar.gz
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PORT 8888
CMD ["/app/bin/trellifier", "foreground"]
