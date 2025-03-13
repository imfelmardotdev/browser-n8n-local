FROM python:3.11-slim

WORKDIR /app

# Install essential packages and dependencies needed for Playwright
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    procps \
    unzip \
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
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Create a data directory with proper permissions
RUN mkdir -p /app/data && chmod 777 /app/data

# Expose the port the app runs on
EXPOSE 8000

# Install Playwright browsers (Run as root)
RUN playwright install

# Create a non-root user to run the app
RUN adduser --disabled-password --gecos "" appuser
RUN chown -R appuser:appuser /app

# Switch to appuser
USER appuser

# Set healthcheck to ensure the service is running properly
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/api/v1/ping || exit 1

# Run the app (Use Gunicorn if it's FastAPI/Flask)
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app:app", "--bind", "0.0.0.0:8000"]
