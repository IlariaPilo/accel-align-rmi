FROM rust

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


WORKDIR /home/accel-align-rmi

# Run a shell as first operation
CMD ["/bin/bash"]