FROM alpine:3.8 as builder
ARG PHP_BUILD_DEP=${PHP_BUILD_DEP:-}
RUN apk update && apk --no-cache add --virtual build-dependencies \
	autoconf automake bison dpkg dpkg-dev file g++ gcc git libtool make re2c \
	${PHP_BUILD_DEP}
RUN git clone https://github.com/php/php-src.git
ARG PHP_CONF=${PHP_CONF:-}
RUN (cd /php-src \
	&& GNU_BUILD="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& GNU_HOST="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
	&& sed -i 's/-export-dynamic/-all-static/g' sapi/fpm/config.m4 \
	&& ./buildconf && autoreconf \
	&& ./configure --build=$GNU_BUILD --host=$GNU_HOST --prefix= \
		--program-suffix=7 --disable-all --disable-cli --disable-cgi \
		--enable-fpm ${PHP_CONF})
RUN (cd /php-src && make fpm -j "$(nproc)" \
	&& make install-fpm \
	&& strip --strip-all /sbin/php-fpm7)
FROM scratch
LABEL maintainer "Georges Savoundararadj <savoundg@gmail.com>"
COPY --from=builder /sbin/php-fpm7 /sbin/
COPY --from=builder /etc/shadow /etc/shadow
COPY --from=builder /etc/group /etc/group
COPY --from=builder /etc/passwd /etc/passwd
ENTRYPOINT [ "/sbin/php-fpm7", "-FO" ]

