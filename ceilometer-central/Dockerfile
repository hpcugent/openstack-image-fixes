FROM FROM satellite.ugent.be:5000/hpc-ugent-testing-tier1_osp16-osp16_containers-ceilometer-central:16.2
USER "root"
# Copy required files and patch package
COPY ceilometer_pipeline_data_event_definitions.yaml.xdmod.patch /tmp/
COPY patch-2.7.6-11.el8.x86_64.rpm /tmp/
# Patch python files for xdmod
RUN rpm -Uvh /tmp/patch-2.7.6-11.el8.x86_64.rpm
RUN patch /usr/lib/python3.6/site-packages/ceilometer/pipeline/data/event_definitions.yaml < /tmp/ceilometer_pipeline_data_event_definitions.yaml.xdmod.patch

