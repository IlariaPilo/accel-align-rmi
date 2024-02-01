FROM rust

# ------- install correct TBB implementation ------- #
RUN curl -LJO https://github.com/oneapi-src/oneTBB/archive/refs/tags/2019_U5.tar.gz
RUN tar -xzvf oneTBB-2019_U5.tar.gz
RUN cd oneTBB-2019_U5 && make
RUN rm oneTBB-2019_U5.tar.gz

# Install some stuff
RUN apt-get update && \
    # apt-get install -y vim libtbb-dev git python python3-pip sudo zstd
    # apt-get install -y libtbb-dev vim
    apt-get install -y vim

RUN echo 'echo "\
===================\n\
= accel-align-rmi =\n\
===================\n\
"'\
> /root/.bashrc

# modify the Makefile
RUN echo \
"sed -Ei 's|^TBB_INCLUDE = .*\$|TBB_INCLUDE = /oneTBB-2019_U5/include|' /home/accel-align-rmi/Makefile"\
>> /root/.bashrc
RUN echo \
"sed -Ei 's|^TBB_LIB = .*\$|TBB_LIB = /oneTBB-2019_U5/build/linux_intel64_gcc_cc11_libc2.35_kernel5.15.0_release|' /home/accel-align-rmi/Makefile"\
>> /root/.bashrc

WORKDIR /home/accel-align-rmi

# Run a shell as first operation
CMD ["/bin/bash"]