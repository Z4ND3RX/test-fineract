# Etapa de construcción
FROM gradle:8.10.2-jdk21 AS builder
WORKDIR /fineract
COPY . .
RUN --mount=type=cache,target=/home/gradle/.gradle/caches \
    gradle --no-daemon bootJar -x test --stacktrace --info && \
    # Verificar que el JAR se generó correctamente
    ls -la /fineract/fineract-provider/build/libs/

# Etapa de ejecución
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=builder /fineract/fineract-provider/build/libs/*.jar ./fineract-provider.jar

# Configuración de usuario seguro
RUN addgroup --system fineract && \
    adduser --system --ingroup fineract fineract && \
    chown -R fineract:fineract /app

USER fineract

EXPOSE 8443

ENTRYPOINT ["sh", "-c", "exec java ${JAVA_OPTS} -jar fineract-provider.jar"]