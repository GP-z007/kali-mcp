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
    hydra \
    aircrack-ng \
    john \
    netcat-openbsd \
    responder \
    bettercap \
    hashcat \
    wifite \
    tshark \
    gobuster \
    ettercap-text-only \
    snort \
    commix \
    macchanger \
    amass \
    theharvester \
    subfinder \
    fierce \
    dnsrecon \
    libimage-exiftool-perl \
    metagoofil \
    spiderfoot \
    eyewitness \
    traceroute \
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

# Install additional Python OSINT tools that provide CLI entrypoints.
RUN pip install --no-cache-dir maigret sherlock-project

# Install Linux-friendly credential-analysis fallback for mimikatz-like workflows.
RUN pip install --no-cache-dir pypykatz

# Install Photon and FinalRecon from source and expose executable wrappers.
RUN git clone --depth 1 https://github.com/s0md3v/Photon.git /opt/photon && \
    git clone --depth 1 https://github.com/thewhiteh4t/FinalRecon.git /opt/finalrecon && \
    printf '#!/bin/sh\nexec python3 /opt/photon/photon.py "$@"\n' > /usr/local/bin/photon && \
    printf '#!/bin/sh\nexec python3 /opt/finalrecon/finalrecon.py "$@"\n' > /usr/local/bin/finalrecon && \
    chmod +x /usr/local/bin/photon /usr/local/bin/finalrecon

# Compatibility wrappers for common command names expected by MCP tools.
RUN printf '#!/bin/sh\nif command -v sherlock >/dev/null 2>&1; then exec sherlock "$@"; fi\nif command -v maigret >/dev/null 2>&1; then exec maigret "$@"; fi\necho "whatsmyname fallback unavailable" >&2\nexit 127\n' > /usr/local/bin/whatsmyname && \
    printf '#!/bin/sh\nif command -v eyewitness >/dev/null 2>&1; then exec eyewitness "$@"; fi\nif [ -f /usr/share/eyewitness/EyeWitness.py ]; then exec python3 /usr/share/eyewitness/EyeWitness.py "$@"; fi\nif [ -f /opt/EyeWitness/Python/EyeWitness.py ]; then exec python3 /opt/EyeWitness/Python/EyeWitness.py "$@"; fi\necho "EyeWitness not available" >&2\nexit 127\n' > /usr/local/bin/EyeWitness && \
    printf '#!/bin/sh\nif command -v pypykatz >/dev/null 2>&1; then exec pypykatz "$@"; fi\necho "mimikatz is Windows-only; pypykatz fallback not installed" >&2\nexit 127\n' > /usr/local/bin/mimikatz && \
    printf '#!/bin/sh\nif command -v metagoofil >/dev/null 2>&1; then exec metagoofil "$@"; fi\necho "foca CLI unavailable; metagoofil fallback not installed" >&2\nexit 127\n' > /usr/local/bin/foca && \
    chmod +x /usr/local/bin/whatsmyname /usr/local/bin/EyeWitness /usr/local/bin/mimikatz /usr/local/bin/foca

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