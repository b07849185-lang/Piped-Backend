# Stage 1: Build
FROM ubuntu:26.04 AS build

# تنزيل الجافا المطلوبة للمشروع
RUN apt-get update && apt-get install -y openjdk-21-jdk-headless

WORKDIR /app/

COPY . /app/

# إصلاح المشكلة: لو ملف VERSION مش موجود، هيتم إنشاؤه تلقائياً
RUN [ -f VERSION ] || echo "v1.0.0" > VERSION

RUN --mount=type=cache,target=/root/.gradle/caches/ \
 ./gradlew shadowJar

# Stage 2: Runtime
FROM ubuntu:26.04

RUN apt-get update && \
 apt-get install -y --no-install-recommends \
  openjdk-21-jre-headless \
  curl \
  && \
 apt-get clean && \
 rm -rf /var/lib/apt/lists/*

WORKDIR /app/

COPY hotspot-entrypoint.sh docker-healthcheck.sh /

COPY --from=build /app/build/libs/piped-1.0-all.jar /app/piped.jar

# ننسخ الملف من الـ build stage عشان ييجي معانا سواء كان موجود أو اتكريت
COPY --from=build /app/VERSION .

# إضافة خصائص الـ JVM لزيادة الأداء
ENV JAVA_OPTS="-XX:+UseZGC -XX:+ZGenerational"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 CMD /docker-healthcheck.sh
ENTRYPOINT ["/hotspot-entrypoint.sh"]
