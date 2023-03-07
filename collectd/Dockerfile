#adding monitoring scripts into collectd container
FROM satellite.ugent.be:5000/hpc-ugent-testing-tier1_osp16-rhosp16_containers-collectd:16.2
USER "root"
COPY openssl-1.1.1g-16.el8_4.x86_64.rpm /tmp/
RUN rpm -Uvh /tmp/openssl-1.1.1g-16.el8_4.x86_64.rpm
COPY endpoints_monitoring.sh /opt/
COPY functional_tests.sh /opt/
COPY ceph_health_monitor.sh /opt/
COPY ssl_monitoring.sh /opt/
COPY configrc /opt/
