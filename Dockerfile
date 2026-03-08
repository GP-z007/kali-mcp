FROM kalilinux/kali-rolling:latest

WORKDIR /app

ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Update and install security tools + Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    nmap \
    nikto \
    sqlmap \
    wpscan \
    dirb \
    metasploit-framework \
    exploitdb \
    hping3 \
    slowhttptest \
    curl \
    wget \
    git \
    libcap2-bin \
    net-tools \
    dnsutils \
    whois \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install SlowLoris via git
RUN git clone https://github.com/gkbrk/slowloris.git /opt/slowloris

# Set up Python venv
RUN python3 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY kali_pentest_server.py .

# Create non-root user
RUN useradd -m -u 1000 mcpuser && \
    chown -R mcpuser:mcpuser /app && \
    chown -R mcpuser:mcpuser /opt/slowloris

# Grant network capabilities to tools that need raw sockets
RUN setcap cap_net_raw,cap_net_admin+eip /usr/bin/nmap || true
RUN setcap cap_net_raw,cap_net_admin+eip /usr/sbin/hping3 || true

USER mcpuser

CMD ["/app/venv/bin/python", "kali_pentest_server.py"]