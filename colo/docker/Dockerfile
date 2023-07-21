FROM debian:10

RUN apt-get update -y
RUN apt-get install -y curl unzip


# Install zstd
RUN apt-get install -y zstd


# Install nmsgtool
RUN curl -o /etc/apt/trusted.gpg.d/debian-farsightsec.gpg https://dl.farsightsecurity.com/debian/debian-farsightsec.gpg
RUN echo "deb http://dl.farsightsecurity.com/debian stretch-farsightsec main" | tee -a /etc/apt/sources.list.d/debian-farsightsec.list
RUN apt-get update -y
RUN apt-get install -y nmsgtool nmsg-msg-module-sie


# Install AWS CLI
RUN apt-get install -y groff
RUN curl -o /var/tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
RUN cd /var/tmp && unzip awscliv2.zip
RUN cd /var/tmp && ./aws/install


WORKDIR /bin
COPY ./colo/docker/entrypoint.sh /bin
RUN chmod +x /bin/entrypoint.sh

COPY ./colo/docker/compressor.sh /bin
RUN chmod +x /bin/compressor.sh

COPY ./colo/docker/uploader.sh /bin
RUN chmod +x /bin/uploader.sh

ENTRYPOINT ["bash", "entrypoint.sh"]
