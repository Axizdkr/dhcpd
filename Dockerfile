FROM alpine:3.12

RUN apk add --update --no-cache dhcp-server-ldap

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
