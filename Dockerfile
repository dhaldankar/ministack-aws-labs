FROM docker.io/hashicorp/terraform:1.17.2 AS terraform

FROM docker.io/library/node:22.22.0-bookworm-slim
ARG AWS_CLI_VERSION=2.42.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl jq python3 unzip \
    && rm -rf /var/lib/apt/lists/* \
    && case "$(dpkg --print-architecture)" in \
         amd64) arch=x86_64 ;; \
         arm64) arch=aarch64 ;; \
         *) exit 1 ;; \
       esac \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${AWS_CLI_VERSION}.zip" -o /tmp/awscli.zip \
    && unzip -q /tmp/awscli.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscli.zip

COPY --from=terraform /bin/terraform /usr/local/bin/terraform

WORKDIR /opt/lab-site
COPY package.json package-lock.json ./
RUN npm ci
COPY labs/ ./labs/
RUN npm run build

COPY exercises/s3-least-privilege/main.tf exercises/s3-least-privilege/check.sh /opt/exercise/
COPY scripts/start-lab.sh /usr/local/bin/start-lab
RUN chmod +x /usr/local/bin/start-lab /opt/exercise/check.sh

WORKDIR /lab
CMD ["/usr/local/bin/start-lab"]
