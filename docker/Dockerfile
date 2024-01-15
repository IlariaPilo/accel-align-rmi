FROM rust:1.68.2

# Some arguments
ARG USER_ID
ARG GROUP_ID

# Install some stuff
RUN apt-get update && \
    # apt-get install -y vim libtbb-dev git python python3-pip sudo zstd
    apt-get install -y libtbb-dev vim

RUN echo 'echo "\
===================\n\
= accel-align-rmi =\n\
===================\n\
"'\
> /root/.bashrc


WORKDIR /home/aligner/accel-align-rmi

# Run a shell as first operation
CMD ["/bin/bash"]