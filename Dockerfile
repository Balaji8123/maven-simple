FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/maven-simple-0.2-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
