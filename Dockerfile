FROM alpine:3.9 as builder
ARG PHP_BUILD_DEP=${PHP_BUILD_DEP:-}
RUN apk update && apk --no-cache add --virtual build-dependencies \
	autoconf automake bison dpkg dpkg-dev file g++ gcc git libtool make \
	re2c php7-dev \
	${PHP_BUILD_DEP}
ARG PHP_GIT_REF=${PHP_GIT_REF:-master}
RUN git clone https://github.com/php/php-src.git -b ${PHP_GIT_REF}
ARG PHP_CONF=${PHP_CONF:-}
ARG PHP_EXT=${PHP_EXT:-}
RUN (cd /php-src \
	&& GNU_BUILD="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& GNU_HOST="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
	&& CONFIGURE_ARGS="--build=$GNU_BUILD --host=$GNU_HOST --prefix= --program-suffix=7" \
	&& for ext in $PHP_EXT; do \
		(cd /php-src/ext/$ext \
			&& phpize \
			&& ./configure $CONFIGURE_ARGS \
			&& make -j "$(nproc)" \
			&& make install); \
	   done \
	&& ./buildconf --force && autoreconf \
	&& ./configure $CONFIGURE_ARGS \
		--disable-all --disable-cli --disable-cgi --enable-fpm \
		${PHP_CONF} \
	&& make fpm -j "$(nproc)" \
	&& make install-fpm \
	&& strip --strip-all /sbin/php-fpm7)
FROM scratch
LABEL maintainer "Georges Savoundararadj <savoundg@gmail.com>"
COPY --from=builder /usr/lib/php7/modules/*.so /usr/lib/php7/modules/
COPY --from=builder /usr/lib/libxml2.so /usr/lib/
COPY --from=builder /usr/lib/libxml2.so.2 /usr/lib/
COPY --from=builder /usr/lib/libxml2.so.2.9.9 /usr/lib/
COPY --from=builder /lib/libz.so /lib/
COPY --from=builder /lib/libz.so.1 /lib/
COPY --from=builder /lib/libz.so.1.2.11 /lib/
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=builder /lib/libc.musl-x86_64.so.1 /lib/
COPY --from=builder /sbin/php-fpm7 /sbin/
COPY --from=builder /etc/shadow /etc/shadow
COPY --from=builder /etc/group /etc/group
COPY --from=builder /etc/passwd /etc/passwd
ENTRYPOINT [ "/sbin/php-fpm7", "-FO" ]

