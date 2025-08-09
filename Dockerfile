# Etapa de construcción
FROM gradle:8.10.2-jdk21 AS builder

WORKDIR /fineract

# Copiar solo los archivos necesarios para la construcción para aprovechar el cache de Docker
COPY gradle gradle
COPY gradlew .
COPY gradle.properties .
COPY settings.gradle .
COPY build.gradle .
COPY fineract-provider fineract-provider

# Construir con cache de dependencias y solo lo necesario
RUN --mount=type=cache,target=/home/gradle/.gradle/caches \
    gradle --no-daemon bootJar -x compileTest --stacktrace --info

# Etapa de ejecución
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Copiar solo el JAR necesario
COPY --from=builder /fineract/fineract-provider/build/libs/fineract-provider.jar .

# Variables de entorno configurables
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# Variables específicas de Fineract
ENV FINERACT_HIKARI_DRIVER_SOURCE_CLASS_NAME=org.postgresql.Driver
ENV FINERACT_HIKARI_JDBC_URL=jdbc:postgresql://fineract-fiter.c3mmga0ea1qb.us-east-2.rds.amazonaws.com:5432/fineract_tenants
ENV FINERACT_HIKARI_USERNAME=postgres
ENV FINERACT_HIKARI_PASSWORD=240877z4ND3RX#
ENV SPRING_PROFILES_ACTIVE=prod

# Usar un usuario no root para mayor seguridad
RUN addgroup --system fineract && \
    adduser --system --ingroup fineract fineract && \
    chown -R fineract:fineract /app

USER fineract

EXPOSE 8443

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar fineract-provider.jar"]