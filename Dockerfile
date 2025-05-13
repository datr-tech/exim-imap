FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG EXIM_IMAP_ADMIN
ARG EXIM_IMAP_ADMIN_DIR
ARG EXIM_IMAP_ADMIN_GRP
ARG EXIM_IMAP_ADMIN_SHELL
ARG EXIM_IMAP_AUTHOR
ARG EXIM_IMAP_CONF
ARG EXIM_IMAP_GRP
ARG EXIM_IMAP_USER
ARG EXIM_IMAP_USER_DIR
ARG EXIM_IMAP_USER_GRP
ARG EXIM_IMAP_USER_PASS
ARG EXIM_IMAP_USER_SHELL
ARG EXIM_IMAP_USER_SYS

LABEL authors=$EXIM_IMAP_AUTHOR

RUN apt update -y \
	&& apt install \
		dovecot-core \
		dovecot-imapd \
		dovecot-pop3d \
		libsasl2-modules \
		sasl2-bin -y \
	&& apt clean	-y \
	&& groupadd $EXIM_IMAP_GRP -f \
	&& useradd -m \
		-d $EXIM_IMAP_ADMIN_DIR \
		-g $EXIM_IMAP_ADMIN_GRP \
		-s $EXIM_IMAP_ADMIN_SHELL \
		$EXIM_IMAP_ADMIN \
	&& useradd -m  \
		-d $EXIM_IMAP_USER_DIR \
		-g $EXIM_IMAP_USER_GRP \
		-s $EXIM_IMAP_USER_SHELL \
		$EXIM_IMAP_USER \
	&& echo "$EXIM_IMAP_USER:$EXIM_IMAP_USER_PASS" | chpasswd

USER $EXIM_IMAP_USER_SYS
COPY $EXIM_IMAP_CONF /etc/dovecot/conf.d/

ENTRYPOINT [ "/usr/sbin/dovecot", "-F" ]
