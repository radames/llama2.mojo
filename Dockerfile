# https://github.com/modularml/mojo/blob/main/examples/docker/Dockerfile.mojosdk
# ===----------------------------------------------------------------------=== #
# Copyright (c) 2023, Modular Inc. All rights reserved.
#
# Licensed under the Apache License v2.0 with LLVM Exceptions:
# https://llvm.org/LICENSE.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ===----------------------------------------------------------------------=== #

# Example command line:
# Use no-cache to force docker to rebuild layers of the image by downloading the SDK from the repos
# docker build --no-cache \
#    --build-arg AUTH_KEY=<your-modular-auth-key>
#    --pull -t modular/mojo-v0.2-`date '+%Y%d%m-%H%M'` \
#    --file Dockerfile.mojosdk .

FROM ubuntu:20.04

ARG DEFAULT_TZ=America/Los_Angeles
ENV DEFAULT_TZ=$DEFAULT_TZ
ARG MODULAR_HOME=/home/user/.modular
ENV MODULAR_HOME=$MODULAR_HOME

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive TZ=$DEFAULT_TZ apt-get install -y \
    tzdata \
    vim \
    sudo \
    curl \
    git \
    wget && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-py38_23.5.2-0-Linux-x86_64.sh > /tmp/miniconda.sh \
    && chmod +x /tmp/miniconda.sh \
    && /tmp/miniconda.sh -b -p /opt/conda

ENV PATH=/opt/conda/bin:$PATH
RUN conda init
RUN pip install \
    jupyterlab \
    ipykernel \
    matplotlib \
    ipywidgets \
    gradio
    
RUN --mount=type=secret,id=MODULAR_AUTH,mode=0444,required=true \
    curl https://get.modular.com | sh - \
    && modular auth $(cat /run/secrets/MODULAR_AUTH) \
    && modular install mojo 

RUN useradd -m -u 1000 user
RUN chown -R user $MODULAR_HOME

ENV PATH="$PATH:/opt/conda/bin:$MODULAR_HOME/pkg/packages.modular.com_mojo/bin"

USER user
WORKDIR $HOME/app

COPY --chown=user . $HOME/app
RUN wget -c -nv https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
RUN wget -c -nv https://huggingface.co/karpathy/tinyllamas/resolve/main/stories42M.bin
RUN wget -c -nv https://huggingface.co/karpathy/tinyllamas/resolve/main/stories110M.bin
RUN wget -c -nv https://huggingface.co/kirp/TinyLlama-1.1B-Chat-v0.2-bin/resolve/main/tok_tl-chat.bin
RUN wget -c -nv https://huggingface.co/kirp/TinyLlama-1.1B-Chat-v0.2-bin/resolve/main/tl-chat.bin

# CMD ["mojo", "llama2.mojo"]
CMD ["python3", "gradio_app.py"]