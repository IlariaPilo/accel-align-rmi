FROM rust:1.68.2

# Some arguments
ARG USER_ID
ARG GROUP_ID

# Install some stuff
RUN apt-get update && \
    apt-get install -y vim git libtbb-dev python python3-pip sudo zstd

# Create a new user called "aligner" (the default user)
# Add it to the sudo group
RUN groupadd -g ${GROUP_ID} aligner &&\
    useradd -m -u ${USER_ID} -g aligner -G sudo aligner
# Add password
RUN echo "aligner:password" | chpasswd

USER aligner

WORKDIR /home/aligner

ADD https://api.github.com/repos/IlariaPilo/accel-align-rmi/git/refs/heads/main version.json
RUN git clone --recurse-submodules https://github.com/IlariaPilo/accel-align-rmi
# Install python dependencies
RUN cd accel-align-rmi && \
    pip install --no-cache-dir -r requirements.txt

WORKDIR /home/aligner/accel-align-rmi

# Run a shell as first operation
CMD ["/bin/bash"]