FROM satellite.ugent.be:5000/hpc-ugent-testing-tier1_osp16-osp16_containers-nova-api:16.1
USER "root"
# https://access.redhat.com/support/cases/#/case/02737714
COPY python3-cryptography-2.6.1-2.el8.x86_64.rpm /tmp/
RUN rpm -Uvh /tmp/python3-cryptography-2.6.1-2.el8.x86_64.rpm

