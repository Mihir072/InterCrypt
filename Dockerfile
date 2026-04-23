# Stage 1: Build stage
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Copy Maven wrapper and configuration from backend directory
COPY backend/mvnw ./
COPY backend/mvnw.cmd ./
COPY backend/.mvn ./.mvn
COPY backend/pom.xml ./

# Copy source code
COPY backend/src ./src

# Build the application
RUN chmod +x mvnw && ./mvnw clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Set working directory
WORKDIR /app

# Add non-root user for security
RUN addgroup -g 1000 appuser && adduser -D -u 1000 -G appuser appuser

# Copy JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose default port (Render will use PORT env variable)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run the application
# Render sets the PORT environment variable, so we pass it to the application
CMD ["java", "-jar", "app.jar", "--spring.profiles.active=prod", "--server.port=${PORT:8080}"]
