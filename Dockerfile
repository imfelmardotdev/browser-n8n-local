# Use Python 3.11 slim as the base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Install essential packages and dependencies needed for Playwright
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    procps \
    unzip \
    curl \
    # Additional dependencies for Playwright
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Create a data directory with proper permissions
RUN mkdir -p /app/data && chmod 777 /app/data

# Expose the port the app runs on
EXPOSE 8000

# Create a non-root user to run the app
RUN adduser --disabled-password --gecos "" appuser

# Give appuser permissions to the necessary directories
RUN chown -R appuser:appuser /app

# Switch to appuser
USER appuser

# Ensure `uvicorn` is in PATH for the non-root user
ENV PATH="/home/appuser/.local/bin:$PATH"

# Install Playwright browsers (run as appuser)
RUN playwright install --with-deps

# Set healthcheck to ensure the service is running properly
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/api/v1/ping || exit 1

# Run the FastAPI app with Uvicorn
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
