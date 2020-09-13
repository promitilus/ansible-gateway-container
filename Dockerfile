FROM ubuntu:18.04 

RUN apt-get update && apt-get install -y --no-install-recommends \
	openssh-client \
	dante-server \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY files/etc /etc
#COPY files/bin /usr/local/bin

COPY scripts/entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh

VOLUME [ "/config" ]
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ] 
CMD [ "--init" ]
