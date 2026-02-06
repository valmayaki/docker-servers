FROM n8nio/n8n:latest

USER root

# Install dependencies required for Chromium (Playwright & Puppeteer)
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-emoji \
    udev \
    ttf-dejavu \
    ttf-liberation \
    git

# Install build tools globally
RUN npm install -g typescript gulp-cli pnpm

# Set env vars to skip browser downloads during build
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Clone and build n8n-playwright from GitHub
RUN cd /tmp && \
    git clone https://github.com/valmayaki/n8n-playwright.git && \
    cd n8n-playwright && \
    pnpm install && \
    pnpm run build && \
    mkdir -p /usr/local/lib/node_modules/n8n/node_modules/n8n-nodes-playwright && \
    cp -r dist package.json /usr/local/lib/node_modules/n8n/node_modules/n8n-nodes-playwright/ && \
    rm -rf /tmp/n8n-playwright

# Install n8n-nodes-puppeteer from npm
RUN cd /tmp && \
    npm pack n8n-nodes-puppeteer && \
    tar -xzf n8n-nodes-puppeteer-*.tgz && \
    mkdir -p /usr/local/lib/node_modules/n8n/node_modules/n8n-nodes-puppeteer && \
    cp -r package/* /usr/local/lib/node_modules/n8n/node_modules/n8n-nodes-puppeteer/ && \
    rm -rf /tmp/n8n-nodes-puppeteer-*.tgz /tmp/package

# Set browser executable paths for runtime
ENV PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

USER node
