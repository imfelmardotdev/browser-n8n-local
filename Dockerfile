# Use a slim Python 3.11 base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for Playwright
RUN apt-get update && apt-get install -y \
    libpango-1.0-0 \
    libcairo2 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Install Playwright and required dependencies
RUN pip install --no-cache-dir playwright && playwright install --with-deps

# Copy the application code
COPY . .

# Ensure the data directory exists and has correct permissions
RUN mkdir -p /app/data && chmod 777 /app/data

# Create a non-root user
RUN useradd -m appuser
RUN chown -R appuser:appuser /app

# Expose the application port
EXPOSE 8000

# Ensure `uvicorn` is accessible
ENV PATH="/home/appuser/.local/bin:$PATH"

# Run as non-root user
USER appuser

# Run the FastAPI app with Uvicorn
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
