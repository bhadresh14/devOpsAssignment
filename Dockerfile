# ---------- Stage 1: build ----------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:17-jre-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app
COPY --from=build --chown=app:app /build/target/hello-service.jar app.jar

USER app

ENV SERVER_PORT=8080 \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:${SERVER_PORT}/health || exit 1

ENTRYPOINT ["java", "-jar", "/app/app.jar"]