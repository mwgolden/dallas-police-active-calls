# Use a Python base image
FROM python:3.12-slim

# Set environment
ARG ENVIRONMENT
ENV ENV=$ENVIRONMENT

# Set the working directory
WORKDIR /app

# Copy the Python script to the container
COPY ./server ./


# Install required Python package
RUN pip install -r requirements.txt

# Expose the port the server will run on
EXPOSE 8000

# Run the WebSocket server
CMD ["fastapi", "run", "server.py"]
