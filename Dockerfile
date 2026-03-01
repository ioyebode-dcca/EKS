# Pin exact version — no surprise breaks from upstream updates
FROM nginx:1.25-alpine

# Image metadata
LABEL maintainer="israel@underwater.com"
LABEL app="octopus-underwater-app"
LABEL version="1.0"

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Add hardened nginx config with security headers
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files with correct ownership
COPY --chown=nginx:nginx static /usr/share/nginx/html

# Verify files copied during build
RUN ls -la /usr/share/nginx/html

# Health check built into the image
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
