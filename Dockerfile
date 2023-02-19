FROM nginx:alpine
COPY static /usr/share/nginx/html

COPY kubectl /bin/kubectl
