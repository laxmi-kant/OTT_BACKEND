FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -S ottapp && adduser -S ottapp -G ottapp

ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

RUN chown -R ottapp:ottapp /app
USER ottapp

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8082/actuator/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseContainerSupport", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+UseG1GC", \
    "-jar", "app.jar"]
