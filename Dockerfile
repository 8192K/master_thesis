FROM condaforge/miniforge3

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# CRITICAL: Since we are not using the official NVIDIA image, we must manually set 
# these environment variables so the NVIDIA Container Runtime knows to expose the GPUs.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG HOST_UNAME=sebastian

# switch to German mirror to speed up apt-get
RUN sed -i 's/archive.ubuntu.com/de.archive.ubuntu.com/g' /etc/apt/sources.list.d/ubuntu.sources

# 2a. Install Tex as first dependency so later build calls don't have to fetch this big package
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-full \
    latexmk \
    biber \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential bash-completion \
    git \
    openssh-client \
    nano less curl \
    && apt-get upgrade -y \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Check if UID/GID exist. If yes, rename them. If no, create them.
RUN \
    if getent group ${HOST_GID} > /dev/null 2>&1; then \
        EXISTING_GROUP=$(getent group ${HOST_GID} | cut -d: -f1); \
        groupmod -n ${HOST_UNAME} $EXISTING_GROUP; \
    else \
        groupadd -g ${HOST_GID} ${HOST_UNAME}; \
    fi && \
    if getent passwd ${HOST_UID} > /dev/null 2>&1; then \
        EXISTING_USER=$(getent passwd ${HOST_UID} | cut -d: -f1); \
        usermod -l ${HOST_UNAME} -g ${HOST_GID} -d /home/${HOST_UNAME} -m $EXISTING_USER; \
    else \
        useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash ${HOST_UNAME}; \
    fi

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER ${HOST_UNAME}

RUN mamba shell init --shell bash --root-prefix=~/.local/share/mamba

ENV MAMBA_ROOT_PREFIX=~/.local/share/mamba

# Use mamba to create the environment with Python 3.13, CUDA 13.0, and your requested packages.
# We include the 'rapidsai' channel which is required for cuml and dask-cuda.
RUN mamba create -y -n dev-env \
    python=3.14 \
    cuda-toolkit=13 \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn \
    scipy \
    pandoc \
    dask \
    graphviz \
    dask-cuda \
    cuml \
    -c rapidsai -c nvidia -c conda-forge && \
    mamba clean -afy

# Set up the environment paths so the container defaults to using the new dev-env
ENV CONDA_DEFAULT_ENV=dev-env

# Ensure interactive shells also activate the environment
RUN echo "mamba activate dev-env" >> ~/.bashrc

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]