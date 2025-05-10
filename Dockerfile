FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update              -y && \
    apt install                   \
      dovecot-core                \
      dovecot-imapd               \
      dovecot-pop3d               \
      libsasl2-modules            \
      sasl2-bin             -y && \
    apt clean               -y && \
    groupadd mail -f           && \
    useradd -m                    \
     -d /home/admin               \
     -g mail                      \
     -s /usr/bin/bash             \
     admin                     && \
    useradd -m                    \
     -d /home/Debian-exim         \
     -g mail                      \
     -s /usr/bin/bash             \
     Debian-exim               && \
    useradd -m                    \
     -d /home/${IMAP_USER} \
     -g mail                      \
     -s /usr/bin/bash             \
     joealdersonstrachan       && \
     echo "${IMAP_USER}:${IMAP_PASS}" | chpasswd

COPY ./conf /etc/dovecot/conf.d/

ENTRYPOINT [ "/usr/sbin/dovecot", "-F" ]
