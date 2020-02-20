###############################################################################
# Dockerfile for https://github.com/ppwwyyxx/speaker-recognition
# -----------------------------------------------------------------------------
# Docker provides a way to run applications securely isolated in a container, 
# packaged with all its dependencies and libraries.
#
# This Dockerfile produces a docker image, from which containers can be created
# * An image is a lightweight, stand-alone, executable package that includes 
#   everything needed to run a piece of software, including the code, a runtime,
#   libraries, environment variables, and config files.
# * A container is a runtime instance of an image – what the image becomes in
#   memory when actually executed. It runs completely isolated from the host 
#   environment by default, only accessing host files and ports if configured 
#   to do so.
#
# Containers run apps natively on the host machine’s kernel. 
# They have better performance than virtual machines that only get virtual
# access to host resources through a hypervisor. 
# Images or containers can easily be exchanged and many users publish images in
# the docker hub (https://hub.docker.com/).  Docker further enables upscaling
# of solutions from single workstation to server farms through docker swarms.
#
#      Read more here: https://docs.docker.com/
# Install docker here: https://docs.docker.com/engine/installation/linux/
#
# Quick start commands (as root)
# -----------------------------------------------------------------------------
# Pull an image from the docker hub
# > docker pull <image name>
# 
# Build this Dockerfile (place it in an empty folder and cd to it): 
# > docker build -f Dockerfile -t speaker-recognition .
#
# Instantiate a container from an image
# > docker run -ti speaker-recognition
# To give container access to host files during development:
# > docker run --name speaker-recognitionInstance -ti -v /:/host speaker-recognition
#
# Run a stopped container
# > docker start -ai speaker-recognitionInstance
# 
# Run the speaker_recognition.py directly thorough the configured entry point
# > docker run -v local_path:remote_path speaker-recognition
#
# List information
# > docker images                 All docker images
# > docker ps -a                  All docker containers (running or not: -a)
#
###############################################################################
# BASE IMAGE
FROM ubuntu
ENV DEBIAN_FRONTEND=noninteractive

# Prepare package management
###############################################################################
RUN apt-get update && \
    apt-get install -y nano sudo tzdata apt-utils && \
    apt-get -y dist-upgrade


# Set timezone
# https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
###############################################################################
RUN rm /etc/localtime && echo "Poland/Warsaw" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata


# Create the GUI User
###############################################################################
# Then you can run a docker container with access to the GUI on your desktop:
# > docker run -ti -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$DISPLAY -u guiuser <image>
# -----------------------------------------------------------------------------
ENV USERNAME guiuser
RUN useradd -m $USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    usermod --shell /bin/bash $USERNAME && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    # Replace 1000 with your user/group id
    usermod  --uid 1000 $USERNAME && \
    groupmod --gid 1000 $USERNAME


# Python 3
###############################################################################
RUN apt-get update && apt-get install -y python3 python3-pip


# Base Dependencies
###############################################################################
RUN apt-get install -y portaudio19-dev libopenblas-base libopenblas-dev pkg-config git-core cmake python-dev liblapack-dev libatlas-base-dev libboost-all-dev libhdf5-serial-dev libqt4-dev libsvm-dev libvlfeat-dev  python-nose python-setuptools build-essential libmatio-dev python-sphinx python-matplotlib python-scipy
# additional dependencies for bob
RUN apt-get install -y libfftw3-dev libtiff5-dev libgif-dev libpng-dev libjpeg-dev

# Spear
# https://gitlab.idiap.ch/bob/bob/wikis/Dependencies
# Takes a very long time to install python packages because compilation is happening in the background
###############################################################################

RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && apt-get -qq -y remove curl bzip2 \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes
ENV PATH /opt/conda/bin:$PATH

RUN conda install numpy
RUN conda install scipy 
RUN conda install scikit-learn
RUN conda install PyAudio
RUN conda install h5py
RUN conda install -c conda-forge/label/broken bob.extension
RUN conda install -c conda-forge/label/broken bob.blitz
RUN conda install -c conda-forge/label/broken bob.core
RUN conda install -c conda-forge/label/broken bob.io.base
RUN conda install -c conda-forge/label/broken bob.bio.spear
RUN conda install -c conda-forge/label/broken bob.sp

RUN pip3 install PySide2
RUN pip3 install argparse


# Realtime Speaker Recognition
# https://github.com/ppwwyyxx/speaker-recognition
###############################################################################
RUN cd ~/ && \
    git clone https://github.com/ppwwyyxx/speaker-recognition.git && \
    cd ~/speaker-recognition && \
    make -C src/gmm


# Clean up
###############################################################################
RUN apt-get clean &&apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Entrypoint - so `docker run speaker-recognition` will automatically run the python main
###############################################################################
ENTRYPOINT ["/usr/bin/python", "/root/speaker-recognition/src/speaker-recognition.py"]
