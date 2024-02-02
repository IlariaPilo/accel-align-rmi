FROM rust

# ------- install correct TBB implementation ------- #
RUN curl -LJO https://github.com/oneapi-src/oneTBB/archive/refs/tags/v2020.3.tar.gz
RUN tar -xzvf oneTBB-2020.3.tar.gz
RUN rm oneTBB-2020.3.tar.gz
RUN cd oneTBB-2020.3 && make
RUN cd oneTBB-2020.3/build; \
    chmod +x *.sh; \
    sh generate_tbbvars.sh \
    sh tbbvars.sh
RUN cd oneTBB-2020.3/build/linux_intel64_gcc_*_release; \
    cp *.so /usr/lib; \
    cp *.so.2 /usr/lib; \
    /sbin/ldconfig
RUN cd oneTBB-2020.3/include; \
    cp -rf ./* /usr/local/include

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
# RUN echo \
# "sed -Ei 's|^TBB_INCLUDE = .*\$|TBB_INCLUDE = /oneTBB-2019_U5/include|' /home/accel-align-rmi/Makefile"\
# >> /root/.bashrc
# RUN echo \
# "sed -Ei 's|^TBB_LIB = .*\$|TBB_LIB = /oneTBB-2019_U5/build/linux_intel64_gcc_cc11_libc2.35_kernel5.15.0_release|' /home/accel-align-rmi/Makefile"\
# >> /root/.bashrc

WORKDIR /home/accel-align-rmi

# Run a shell as first operation
CMD ["/bin/bash"]