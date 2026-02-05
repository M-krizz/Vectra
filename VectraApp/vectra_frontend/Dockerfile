# Dockerfile for Vectra Frontend Development
FROM ubuntu:22.04

# Prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set up user
WORKDIR /app
ENV USER=flutter_user
ENV UID=1000
ENV GID=1000

# Install Flutter SDK
ENV FLUTTER_HOME=/usr/local/flutter
ENV PATH=${FLUTTER_HOME}/bin:${PATH}

RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    cd ${FLUTTER_HOME} && \
    git checkout stable

# Pre-download development binaries
RUN flutter config --no-analytics && \
    flutter precache

# Enable web support
RUN flutter config --enable-web

# Accept licenses
RUN yes | flutter doctor --android-licenses || true

# Check setup
RUN flutter doctor

# Copy project files
COPY . .

# Get dependencies
RUN flutter pub get

# Build for web (for dev serving)
# Or run "flutter run -d web-server" for development
CMD ["flutter", "run", "-d", "web-server", "--web-port", "3000", "--web-hostname", "0.0.0.0"]
