FROM alpine:3.9 as builder
ARG PHP_BUILD_DEP=${PHP_BUILD_DEP:-}
ARG PHP_RUNTIME_DEP=${PHP_RUNTIME_DEP:-}
RUN apk update && apk --no-cache add --virtual build-dependencies \
	autoconf automake bison dpkg dpkg-dev file g++ gcc git libtool make \
	re2c php7-dev \
	${PHP_BUILD_DEP} \
	${PHP_RUNTIME_DEP}
ARG PHP_GIT_REF=${PHP_GIT_REF:-master}
RUN git clone --depth 1 https://github.com/php/php-src.git -b ${PHP_GIT_REF}
ARG PHP_CONF=${PHP_CONF:-}
# FIXME: install gnu-libiconv when available from an Alpine release
RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community gnu-libiconv-dev
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
ARG USR_BIN=${USR_BIN:-}
ARG USR_LIB=${USR_LIB:-}
ARG BIN=${BIN:-}
ARG LIB=${LIB:-}
RUN (touch /usr/lib/php7/modules/dummy.so)
RUN (mkdir -p /sysroot/usr/bin/ /sysroot/bin/ /sysroot/usr/lib/ /sysroot/lib/ \
	&& for bins in $USR_BIN; do cp -v /usr/bin/${bins} /sysroot/usr/bin/; done \
	&& for libs in $USR_LIB; do cp -v /usr/lib/*lib${libs}*.so* /sysroot/usr/lib/; done \
	&& for bins in $BIN; do cp -v /bin/${bins} /sysroot/bin/; done \
	&& for libs in $LIB; do cp -v /lib/*lib${libs}*.so* /sysroot/lib/; done)
RUN (for php_runtime_dep in $PHP_RUNTIME_DEP; do \
	for file in $(apk info -L $php_runtime_dep); do \
		FOLDER=/sysroot/$(dirname $file); mkdir -p $FOLDER; cp $file $FOLDER; \
	done; done 2> /dev/null)
FROM scratch
LABEL maintainer "Georges Savoundararadj <savoundg@gmail.com>"
ARG PHP_BUILD_DEP=${PHP_BUILD_DEP:-}
ARG PHP_RUNTIME_DEP=${PHP_RUNTIME_DEP:-}
ARG PHP_GIT_REF=${PHP_GIT_REF:-master}
ARG PHP_CONF=${PHP_CONF:-}
ARG PHP_EXT=${PHP_EXT:-}
ARG USR_BIN=${USR_BIN:-}
ARG USR_LIB=${USR_LIB:-}
ARG BIN=${BIN:-}
ARG LIB=${LIB:-}
LABEL PHP_BUILD_DEP=${PHP_BUILD_DEP}
LABEL PHP_RUNTIME_DEP=${PHP_RUNTIME_DEP}
LABEL PHP_GIT_REF=${PHP_GIT_REF}
LABEL PHP_CONF=${PHP_CONF}
LABEL PHP_EXT=${PHP_EXT}
LABEL USR_BIN=${USR_BIN}
LABEL USR_LIB=${USR_LIB}
LABEL BIN=${BIN}
LABEL LIB=${LIB}
COPY --from=builder /usr/lib/php7/modules/*.so /usr/lib/php7/modules/
COPY --from=builder /sysroot/usr/bin/ /usr/bin/
COPY --from=builder /sysroot/usr/lib/ /usr/lib/
COPY --from=builder /sysroot/lib/ /lib/
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/
COPY --from=builder /lib/libc.musl-x86_64.so.1 /lib/
COPY --from=builder /sbin/php-fpm7 /sbin/
COPY --from=builder /etc/shadow /etc/shadow
COPY --from=builder /etc/group /etc/group
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /bin/ /bin/
RUN mkdir /tmp/ && chmod -R 777 /tmp/ && rm -rf /bin/
COPY --from=builder /sysroot/bin/ /bin/
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so
ENTRYPOINT [ "/sbin/php-fpm7", "-FO" ]

