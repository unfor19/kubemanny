FROM segment/chamber:2.7.5 as chamber

FROM nikolaik/python-nodejs:python3.8-nodejs12 AS build
RUN apt -qq update && apt -qq install -y curl unzip
WORKDIR /build/
COPY --from=chamber /chamber /build/
RUN curl --silent -o /build/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
    && curl --silent -OL https://github.com/kubeless/kubeless/releases/download/v1.0.6/kubeless_linux-amd64.zip \
    && unzip -qq kubeless_linux-amd64.zip \
    && mv bundles/kubeless_linux-amd64/kubeless /build/kubeless \
    && curl --silent --location https://get.helm.sh/helm-v3.1.1-linux-amd64.tar.gz | tar xz -C /tmp/ \
    && curl --silent -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl \
    && curl --silent -o terraform.zip https://releases.hashicorp.com/terraform/0.12.21/terraform_0.12.21_linux_amd64.zip && unzip -qq terraform.zip \
    && curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp \
    && chmod +x /build/kubectl \
    && mv /tmp/eksctl /build/eksctl \
    && mv /tmp/linux-amd64/helm /build/helm \
    && ls -la /build/


FROM nikolaik/python-nodejs:python3.8-nodejs12-alpine AS app
COPY --from=build /build/eksctl /build/kubectl /build/kubeless /build/helm /build/terraform /build/chamber /usr/local/bin/
COPY --from=build /build/.git-prompt.sh /root/.git-prompt.sh

RUN apk add --no-cache bash bash-completion git curl apache2-utils \
    && pip3 install awscli --upgrade --no-cache-dir -q \
    && echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc \
    && echo 'source ~/.git-prompt.sh' >> /root/.bashrc \
    && echo 'export PS1="\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1)$ "' >> /root/.bashrc

WORKDIR /code/

CMD ["bash"]
