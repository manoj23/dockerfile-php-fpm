BUILDER=alpine3.21
PHP_GIT_REF=PHP-8.3
REPO=php-fpm
IMAGE=php-fpm
set -e

IMAGE=php-fpm-mediawiki
#
docker build --no-cache  . \
--build-arg ALPINE_VERSION=3.21 \
--build-arg PHP_GIT_REF=${PHP_GIT_REF} \
--build-arg PHP_CONF="--enable-mbstring --enable-ctype --enable-fileinfo --enable-xml --enable-session --enable-mysqlnd --enable-pdo --with-iconv --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --enable-dom --with-libxml --with-curl --with-zlib --with-openssl --enable-intl --enable-xmlreader --enable-calendar" \
--build-arg PHP_BUILD_DEP="libxml2-dev curl-dev zlib-dev openssl-dev oniguruma-dev icu-dev" \
--build-arg PHP_GIT_REF="${PHP_GIT_REF}" \
--build-arg USR_BIN="env timeout" \
--build-arg USR_LIB="curl ssl crypto nghttp2 xml2 lzma onig icui18n icuuc icuio icudata stdc++ gcc_s z cares idn2 psl unistring brotlicommon brotlidec zstd" \
--build-arg BIN="busybox echo mkdir rmdir sh sleep" \
--build-arg DOCKERFILE_HASH=$(git rev-parse --short HEAD) -t ${IMAGE}:${BUILDER}-${PHP_GIT_REF}

docker tag ${IMAGE}:${BUILDER}-${PHP_GIT_REF}  ghcr.io/manoj23/${IMAGE}:${BUILDER}-${PHP_GIT_REF}

#docker push  ghcr.io/manoj23/${IMAGE}:${BUILDER}-${PHP_GIT_REF}
